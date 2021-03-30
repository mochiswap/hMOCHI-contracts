const { expectRevert, time } = require('@openzeppelin/test-helpers')
const MochiToken = artifacts.require('MochiToken')

const getBalance = async (address) => {
    return (await this.mochiToken.balanceOf(address)).toString()
}

const getTotalSupply = async () => {
    return (await this.mochiToken.totalSupply()).toString()
}

contract('MochiToken', ([_, adminAddress, minterAddress, user1Address, user2Address, user3Address, user4Address, user5Address]) => {
    beforeEach(async () => {
        this.mochiToken = await MochiToken.new({from: adminAddress})
        await this.mochiToken.addMinter(minterAddress, {from: adminAddress})
        await this.mochiToken.renounceMinter({from: adminAddress})
    })

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.mochiToken.name()
        const symbol = await this.mochiToken.symbol()
        const decimals = await this.mochiToken.decimals()
        assert.equal(name.toString(), 'MochiSwap Token')
        assert.equal(symbol.toString(), 'hMOCHI')
        assert.equal(decimals.toString(), '18')
    })

    it('should have correct supply cap', async () => {
        const supplyCap = await this.mochiToken.cap()
        assert.equal(supplyCap.toString(), '100000000000000000000000000')
    })

    it('should have enforce supply cap', async () => {
        const supplyCap = await this.mochiToken.cap()
        assert.equal(supplyCap.toString(), '100000000000000000000000000')
        this.mochiToken.mint(minterAddress, supplyCap, {from: minterAddress})
        // break
        await expectRevert(
            this.mochiToken.mint(minterAddress, 1, {from: minterAddress}),
            'ERC20Capped: cap exceeded'
        )
    })

    it('should only allow minter to mint token and users to burn', async () => {
        await this.mochiToken.mint(adminAddress, '100', { from: minterAddress })
        await this.mochiToken.mint(user1Address, '1000', { from: minterAddress })
        await expectRevert(
            this.mochiToken.mint(user2Address, '1000', { from: user1Address }),
            'MinterRole: caller does not have the Minter role',
        )
        await expectRevert(
            this.mochiToken.mint(user2Address, '1000', { from: adminAddress }),
            'MinterRole: caller does not have the Minter role',
        )
        assert.equal('1100', await getTotalSupply())
        assert.equal('100', await getBalance(adminAddress))
        assert.equal('1000', await getBalance(user1Address))
        assert.equal('0', await getBalance(user2Address))

        // delegates update
        await this.mochiToken.delegate(adminAddress, {from: adminAddress})
        await this.mochiToken.delegate(user1Address, {from: user1Address})
        await this.mochiToken.delegate(user2Address, {from: user2Address})
        assert.equal('100', (await this.mochiToken.getCurrentVotes(adminAddress)).toString())
        assert.equal('1000', (await this.mochiToken.getCurrentVotes(user1Address)).toString())
        assert.equal('0', (await this.mochiToken.getCurrentVotes(user2Address)).toString())

        // can burn and update delegates
        await this.mochiToken.burn('100', { from: adminAddress })
        await this.mochiToken.burn('100', { from: user1Address })
        await expectRevert(
            this.mochiToken.burn('100', { from: user2Address }),
            'SafeMath: subtraction overflow',
        )
        assert.equal('900', await getTotalSupply())
        assert.equal('0', await getBalance(adminAddress))
        assert.equal('900', await getBalance(user1Address))
        assert.equal('0', await getBalance(user2Address))

        // delegates update
        assert.equal('0', (await this.mochiToken.getCurrentVotes(adminAddress)).toString())
        assert.equal('900', (await this.mochiToken.getCurrentVotes(user1Address)).toString())
        assert.equal('0', (await this.mochiToken.getCurrentVotes(user2Address)).toString())
    })

    it('should supply token transfers properly', async () => {
        await this.mochiToken.mint(adminAddress, 10000, { from: minterAddress })
        await this.mochiToken.mint(user1Address, 10000, { from: minterAddress })
        await this.mochiToken.transfer(user2Address, 1000, { from: adminAddress })
        await this.mochiToken.transfer(user2Address, 10000, { from: user1Address })
        assert.equal(20000, await getTotalSupply())
        assert.equal(9000, await getBalance(adminAddress))
        assert.equal(0, await getBalance(user1Address))
        assert.equal(11000, await getBalance(user2Address))
    })

    it('should handle micro transfers locks and delegate', async () => {

        // no lock, too small
        await this.mochiToken.mint(adminAddress, '1', { from: minterAddress })
        await this.mochiToken.transfer(user1Address, '1', { from: adminAddress })
        assert.equal((await this.mochiToken.balanceOf(user1Address)).toString(), '1')
        assert.equal((await this.mochiToken.balanceOf(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.totalSupply()).toString(), '1')

        // try delegating
        await this.mochiToken.delegate(user2Address, {from: user1Address})
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '1')

        // no lock, too small
        await this.mochiToken.mint(adminAddress, '10', { from: minterAddress })
        await this.mochiToken.transfer(user1Address, '10', { from: adminAddress })
        assert.equal((await this.mochiToken.balanceOf(user1Address)).toString(), '11')
        assert.equal((await this.mochiToken.balanceOf(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.totalSupply()).toString(), '11')

        // delegating had updated
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '11')

        await this.mochiToken.mint(adminAddress, '100', { from: minterAddress })
        await this.mochiToken.transfer(user1Address, '100', { from: adminAddress })
        assert.equal((await this.mochiToken.balanceOf(user1Address)).toString(), '111')
        assert.equal((await this.mochiToken.balanceOf(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.totalSupply()).toString(), '111')

        // delegating had updated
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '111')

        await this.mochiToken.mint(adminAddress, '1000', { from: minterAddress })
        await this.mochiToken.transfer(user1Address, '1000', { from: adminAddress })
        assert.equal((await this.mochiToken.balanceOf(user1Address)).toString(), '1111')
        assert.equal((await this.mochiToken.balanceOf(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.totalSupply()).toString(), '1111')

        // delegating had updated
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '1111')

        await this.mochiToken.mint(adminAddress, '10000', { from: minterAddress })
        await this.mochiToken.transfer(user1Address, '10000', { from: adminAddress })
        assert.equal((await this.mochiToken.balanceOf(user1Address)).toString(), '11111')
        assert.equal((await this.mochiToken.balanceOf(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.totalSupply()).toString(), '11111')

        // delegating had updated
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '11111')
    })

    it('should fail if you try to do bad transfers', async () => {

        await this.mochiToken.mint(adminAddress, '100', { from: minterAddress })
        await expectRevert(
            this.mochiToken.transfer(user2Address, '110', { from: adminAddress }),
            'ERC20: transfer amount exceeds balance',
        )
        await expectRevert(
            this.mochiToken.transfer(user2Address, '1', { from: user1Address }),
            'ERC20: transfer amount exceeds balance',
        )
    })

    // https://medium.com/bulldax-finance/sushiswap-delegation-double-spending-bug-5adcc7b3830f
    it('should fix delegate transfer bug', async () => {

        await this.mochiToken.mint(adminAddress, '1000000', { from: minterAddress })
        await this.mochiToken.delegate(user3Address, {from: adminAddress})
        await this.mochiToken.transfer(user1Address, '1000000', {from: adminAddress} )
        await this.mochiToken.delegate(user3Address, {from: user1Address})
        await this.mochiToken.transfer(user2Address, '990000', {from: user1Address} )
        await this.mochiToken.delegate(user3Address, {from: user2Address})
        await this.mochiToken.transfer(adminAddress, '980100', {from: user2Address} )
        assert.equal((await this.mochiToken.totalSupply()).toString(), '1000000')
        assert.equal((await this.mochiToken.getCurrentVotes(user3Address)).toString(), '1000000')
        assert.equal((await this.mochiToken.getCurrentVotes(adminAddress)).toString(), '0')
        assert.equal((await this.mochiToken.getCurrentVotes(user1Address)).toString(), '0')
        assert.equal((await this.mochiToken.getCurrentVotes(user2Address)).toString(), '0')
    })
})
