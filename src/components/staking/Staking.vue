<template>
  <div class="staking">
    <b-alert variant="warning" :show="showAlert" class="text-center">You're viewing data from the Main network,
      but your
      wallet is connected to the different network. Please switch to Main network
    </b-alert>
    <b-container class="py-5">
      <b-row class="bg-secondary mx-0 py-3">
        <b-col>
          <b-alert variant="outline-danger" :show="!started">Staking has not started yet!</b-alert>
          <b-tabs justified>
            <b-tab active class="btn-outline-secondary">
              <template #title>
                <strong>Stake</strong>
              </template>
              <b-row class="my-5">
                <b-col class="mt-3 mt-md-0" cols="12" v-if="availableNFTs.length > 0">
                  <b-row class="mt-3 mt-md-0">
                    <b-col cols="2" class="mt-3" v-for="(item) in availableNFTs" :key="item">
                      <figure>
                        <b-img :src="`https://dt.cinnamoon.cc:8080/media/${parseInt(item) + 1}`" fluid
                               :class="selectedNFT == item ? 'selected' : ''"
                               @click="selectNFT(item)"></b-img>

                        <figcaption class="text-center">NFT #{{ parseInt(item) + 1 }}</figcaption>
                      </figure>
                    </b-col>
                  </b-row>
                  <b-row class="mt-3 mt-md-0" v-if="availableNFTs.length > 0">
                    <b-col>
                      <p>Select lock duration</p>
                      <label for="one">
                        <input type="radio" id="one" name="duration" v-model="lockDuration" value="0"
                               :disabled="(unlockTime - new Date().getTime() / 1000) > 0">
                        <span class="btn">No lock</span>
                      </label>
                      <label for="two">
                        <input type="radio" id="two" name="duration" v-model="lockDuration" value="30"
                               :disabled="(unlockTime - new Date().getTime() / 1000) > 30 * DAY">
                        <span class="btn">30 days</span>
                      </label>
                      <label for="three">
                        <input type="radio" id="three" name="duration" v-model="lockDuration" value="60"
                               :disabled="(unlockTime - new Date().getTime() / 1000) > 60 * DAY">
                        <span class="btn">60 days</span>
                      </label>
                      <label for="four">
                        <input type="radio" id="four" name="duration" v-model="lockDuration" value="90"
                               :disabled="(unlockTime - new Date().getTime() / 1000) > 90 * DAY">
                        <span class="btn">90 days</span>
                      </label>
                    </b-col>
                  </b-row>
                  <div class="row align-items-center mt-3 justify-content-between">
                    <div class="col-md-12 col-lg-12 text-center">
                      <div v-if="nftAllowed == 1">
                        <VueLoadingButton
                            v-if="availableNFTs.length > 0 && this.availableNFTs.includes(selectedNFT)"
                            aria-label="Stake" @click.native="stakeNFTs"
                            class="btn btn-primary bg-primary text-white" :styled="false"
                            :loading="nftStakeLoading">Stake
                        </VueLoadingButton>
                      </div>
                      <div v-else>
                        <VueLoadingButton aria-label="Stake" @click.native="approveNFTs"
                                          class="btn btn-primary text-white"
                                          :loading="nftApproveLoading" :styled="false">Allow staking contract to use
                          your
                          NFTs
                        </VueLoadingButton>
                      </div>
                    </div>
                  </div>
                </b-col>
                <b-col v-else class="text-center">
                  You don't have NFTs. Click
                  <b-link href="/">here</b-link>
                  to mint!
                </b-col>
              </b-row>
            </b-tab>
            <b-tab class="btn-outline-secondary" v-if="stakedNFTs.length > 0">
              <template #title>
                <strong>Withdraw</strong>
              </template>
              <b-row class="my-5">
                <b-col class="mt-3 mt-md-0" cols="12" v-if="stakedNFTs.length > 0 || availableNFTs.length > 0">
                  <b-row>
                    <b-col cols="2" v-for="(item) in stakedNFTs" :key="item">
                      <figure>
                        <b-img :src="`https://dt.cinnamoon.cc:8080/media/${parseInt(item) + 1}`" fluid
                               :class="selectedNFT == item ? 'selected' : ''"
                               @click="selectNFT(item)"></b-img>
                        <figcaption class="text-center">NFT #{{ parseInt(item) + 1 }}</figcaption>
                      </figure>
                    </b-col>
                  </b-row>
                  <div class="row align-items-center mt-3 justify-content-between">
                    <div class="col-md-12 col-lg-12 text-center">
                      <div v-if="(unlockTime - new Date().getTime() / 1000) * 1000 > 0" class="text-center my-3">
                        <vue-countdown
                            :time="(unlockTime - new Date().getTime() / 1000) * 1000">
                          <template slot-scope="props">
                            Locked for
                            <span class="highlight"><span v-if="props.days > 0">{{ props.days }} D </span>{{
                                String("00" + props.hours).slice(-2)
                              }}:{{ String("00" + props.minutes).slice(-2) }}:{{
                                String("00" + props.seconds).slice(-2)
                              }}</span>
                          </template>
                        </vue-countdown>
                      </div>
                      <div v-else class="my-3">
                        <VueLoadingButton v-if="stakedNFTs.length > 0 && this.stakedNFTs.includes(selectedNFT)"
                                          aria-label="Stake" @click.native="withdrawNFTs"
                                          class="btn btn-primary bg-primary mr-2 text-white" :styled="false"
                                          :loading="nftWithdrawLoading">Withdraw
                        </VueLoadingButton>
                      </div>
                    </div>
                  </div>
                </b-col>
                <b-col v-else class="text-center">
                  You don't have NFTs. Click
                  <b-link href="/">here</b-link>
                  to mint!
                </b-col>
              </b-row>
            </b-tab>
            <b-tab class="text-center pt-5">
              <template #title>
                <strong>Rewards</strong>
              </template>
              <p>Total claimed: {{ beautifyRewards(fromWei(userInfo.withdrawn, 18)) }} ETH</p>
              <p>Total unclaimed: {{ beautifyRewards(fromWei(rewardsETH, 18)) }} ETH</p>
              <VueLoadingButton aria-label="Stake" @click.native="claimETH(0)" v-if="rewardsETH > 0"
                                class="btn btn-primary rounded-0 rounded-10"
                                :loading="stakeLoading" :styled="false">Claim
              </VueLoadingButton>&nbsp;
              <p class="text-center text-muted mt-3">
                Claim will transfer your ETH rewards from staking contract to your wallet
              </p>
            </b-tab>
          </b-tabs>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<script>
import Web3 from "web3"
import THE from '@/helper/contracts/the'
import TETHER from '@/helper/contracts/tether'
import THELP from '@/helper/contracts/the-lp'
import STAKING from '@/helper/contracts/staking'
import NFT from '@/helper/contracts/nft'
import VueLoadingButton from "vue-loading-button";
import VueCountdown from "@chenfengyuan/vue-countdown";

export default {
  name: "StakingEthereum",
  components: {VueLoadingButton, VueCountdown},
  data: function () {
    return {
      isObservationEnabled: false,
      DAY: 60,
      user: null,
      contract: null,
      stakingContract: null,
      ethCtr: null,
      nftContract: null,
      showAlert: false,
      selectedNFT: null,
      approved: false,
      showModal: false,
      started: true,
      lockDuration: 0,
      stakeAmount: 0,
      nftAllowed: 0,
      tokenUri: "",
      unstakeAmount: 0,
      availableNFTs: [],
      stakedNFTs: [],
      size: Web3.utils.toBN(0),
      sizeUSD: 0,
      nftSize: 0,
      stakedSize: 0,
      unlockTime: 0,
      stakedSizeUSD: 0,
      ethPrice: 0,
      thePrice: 0,
      chainId: 5,
      rewardsETH: Web3.utils.toBN(0),
      poolId: 0,
      userInfo: {
        boostPointsBP: 0,
        lockTimeBoost: 0,
        lockedUntil: 0,
        claimableRWT: 0,
        claimableETH: 0,
        weightedBalance: 0,
        withdrawn: 0,
        ETHrewardDebt: 0,
      },
      poolInfo: {
        lpToken: 0,
        allocPoint: 0,
        lastRewardBlock: 0,
        accRwtPerShare: 0,
        accETHPerShare: 0,
        weightedBalance: 0,
      },
      tlv: 0,
      stakeLoading: false,
      nftStakeLoading: false,
      nftWithdrawLoading: false,
      nftApproveLoading: false,
      loading: false,
    }
  },
  methods: {
    beautifyNumbers: function (number) {
      if (number >= 1000000000) {
        return Math.round(number / 1000000000 * 100) / 100 + 'B'
      } else if (number >= 1000000) {
        return Math.round(number / 1000000 * 100) / 100 + 'M'
      } else if (number >= 1000) {
        return Math.round(number / 1000 * 100) / 100 + 'K'
      } else {
        return Math.round(number * 100) / 100;
      }
    },
    beautifyRewards: function (number) {
      if (parseFloat(number) === 0) {
        return 0.00;
      } else if (parseFloat(number) < 0.0001) {
        return '< 0.0001'
      } else {
        return this.format(number, 6)
      }
    },
    beautifyWallet: function (address) {
      return address.slice(0, 6) + '...' + address.slice(-6)
    },
    format: function (number, digits = 0) {
      return new Intl.NumberFormat('en-US', {
        minimumFractionDigits: digits,
        maximumFractionDigits: digits
      }).format(number)
    },
    start: async function () {
      /*****************************************/
      /* Detect the MetaMask Ethereum provider */
      /*****************************************/

      // this returns the provider, or null if it wasn't detected
      //const provider = await detectEthereumProvider();
      const provider = window.ethereum;

      if (provider) {
        this.startApp(provider); // Initialize your app
      }

      /***********************************************************/
      /* Handle user accounts and accountsChanged (per EIP-1193) */
      /***********************************************************/

      window.ethereum
          .request({method: 'eth_accounts'})
          .then(this.handleAccountsChanged)
          .catch((err) => {
            // Some unexpected error.
            // For backwards compatibility reasons, if no accounts are available,
            // eth_accounts will return an empty array.
            console.error(err);
          });

    },
    startApp: function (provider) {
      // If the provider returned by detectEthereumProvider is not the same as
      // window.ethereum, something is overwriting it, perhaps another wallet.
      if (provider !== window.ethereum) {
        console.error('Do you have multiple wallets installed?');
      }

      let web3js = new Web3(provider);

      web3js.eth.getChainId().then((id) => {
        this.chainId = id

        if (id != THE.chain) {
          this.showAlert = true
        } else {
          this.showAlert = false
          let connected = false
          while (!connected) {
            try {
              this.contract = new web3js.eth.Contract(THE.abi, THE.address)
              this.stakingContract = new web3js.eth.Contract(STAKING.abi, STAKING.address)
              if (this.chainId !== 5) {
                this.usdtCtr = new web3js.eth.Contract(TETHER.abi, TETHER.address)
              }
              this.uniPair = new web3js.eth.Contract(THELP.abi, THELP.address)
              this.nftContract = new web3js.eth.Contract(NFT.abi, NFT.address)
              this.tokenUri = NFT.tokenUri
              connected = true
            } catch (error) {
              console.log(error)
            }
          }
          this.refreshTotalSupply();
        }
      }).catch(err => console.log("Chain select: " + err));
    },
    fromWei: function (number) {
      if (typeof number === "undefined") {
        return 0;
      }
      let type = 'ether'

      return Web3.utils.fromWei(number, type)
    },
    toWei: function (number) {

      let type = 'ether'

      return Web3.utils.toWei(number, type)
    },
    approve: async function () {
      this.loading = true
      let that = this
      return this.contract.methods.approve(STAKING.address, "1000000000000000000000000000").send({
        from: this.user,
        value: 0
      }).on("receipt", function () {
        that.loading = false
      }).on("error", function () {
        that.loading = false
      })
    },
    stake: async function () {
      let amount = Web3.utils.toBN(this.toWei(this.stakeAmount))
      let that = this
      if (amount.gt(this.size)) {
        amount = this.size
      }

      that.loading = true

      return this.stakingContract.methods.deposit(0, amount)
          .send({from: this.user, value: 0})
          .on("receipt", function () {
            console.log("Successful")
            that.loading = false
          })
          .on("error", function () {
            console.log("Failed")
            that.loading = false
          });
    },
    claimETH: async function (pid) {
      let t = this;
      this.stakeLoading = true

      return this.stakingContract.methods.claimRewards(pid)
          .send({from: this.user, value: 0})
          .on("receipt", function () {
            // t.$notification.success("Successfully claimed ETH rewards", {timer: 10});
            t.stakeLoading = false
          })
          .on("error", function () {
            // t.$notification.error("An error occurred while trying to claim earned ETH", {timer: 10});
            t.stakeLoading = false
          });
    },

    withdraw: async function () {
      let amount = Web3.utils.toBN(this.toWei(this.unstakeAmount))
      let that = this

      if (amount.gt(this.userInfo.amount)) {
        amount = this.userInfo.amount
      }

      that.loading = true

      return this.stakingContract.methods.withdraw(0, amount)
          .send({from: this.user, value: 0})
          .on("receipt", function () {
            console.log("Successful")
            that.loading = false
          })
          .on("error", function () {
            console.log("Failed")
            that.loading = false
          });
    },
    stakeNFTs: function () {
      let t = this;

      if (this.availableNFTs.includes(this.selectedNFT)) {
        this.nftStakeLoading = true

        return this.stakingContract.methods.depositNFT(0, NFT.address, parseInt(this.selectedNFT), this.lockDuration * this.DAY)
            .send({from: this.user, value: 0})
            .on("receipt", function () {
              t.nftStakeLoading = false
            })
            .on("error", function () {
              t.nftStakeLoading = false
            })
      } else {
        alert("Please select one of the available NFTs")
      }
    },
    withdrawNFTs: function () {
      let t = this;
      if (this.stakedNFTs.includes(this.selectedNFT)) {

        this.nftWithdrawLoading = true

        return this.stakingContract.methods.withdrawNFT(0, NFT.address, parseInt(this.selectedNFT))
            .send({from: this.user, value: 0})
            .on("receipt", function () {
              t.nftWithdrawLoading = false
            })
            .on("error", function () {
              t.nftWithdrawLoading = false
            })
      } else {
        alert("Please select one of the staked NFTs")
      }
    },
    approveNFTs: async function () {
      this.nftApproveLoading = true
      let t = this
      return this.nftContract.methods.setApprovalForAll(STAKING.address, true).send({
        from: this.user,
        value: 0
      }).on("receipt", function () {
        t.nftApproveLoading = false
      }).on("error", function () {
        t.nftApproveLoading = false
      })
    },
    getUser: async function () {
      if (this.user) {
        this.stakingContract.methods.userInfo(this.poolId, this.user).call().then(res => {
          this.userInfo = res

          if (this.unlockTime != res.lockedUntil) {
            this.unlockTime = res.lockedUntil
          }

        }).catch(err => console.log("getUser: " + err))
      }

      return this
    },
    getPoolInfo: async function () {
      if (this.user) {
        this.stakingContract.methods.poolInfo(this.poolId).call().then(res => {
          this.poolInfo = res
        }).catch(err => console.log("getPoolInfo: " + err))
      }

      return this
    },
    selectNFT: function (id) {
      if (id === this.selectedNFT) {
        this.selectedNFT = null
      } else {
        this.selectedNFT = id
      }
    },
    getSize: function () {
      if (this.user != null) {
        return this.contract.methods.balanceOf(this.user).call().then(res => {
          this.size = Web3.utils.toBN(res)
        }).catch(err => {
          console.log("getSize:")
          console.log(err)
        })
      }
      return this
    },
    getNFTSize: async function () {
      if (this.user) {
        return this.nftContract.methods.walletOfOwner(this.user).call().then(res => {
          this.availableNFTs = res;
        })
      }

      return false
    },
    getDepositedNFTs: function () {
      if (this.user) {
        this.stakingContract.methods.getUsersNFTs(0, this.user).call().then(res => {
          this.stakedNFTs = res[1]
        }).catch(err => console.log("getUser: " + err))
      }
      return this
    },
    getThePrice: async function () {
      this.weth = 0;

      await this.uniPair.methods.token0().call().then(res => {
        if (res.toString().toLowerCase() === (THE.address).toString().toLowerCase()) {
          this.weth = 1
        }
      })

      return this.uniPair.methods.getReserves().call().then(res => {
        if (this.weth === 0) {
          this.thePriceEth = (res[0] / 10 ** 18) / (res[1] / 10 ** 18)
        } else {
          this.thePriceEth = (res[1] / 10 ** 18) / (res[0] / 10 ** 18)
        }
        this.thePrice = this.thePriceEth * this.ethPrice

      }).catch(err => console.log("getUniPairReserves: " + err))
    },
    getEthPrice: async function () {
      if (THE.chain == 5) {
        this.ethPrice = 1600
      } else {
        this.usdweth = 0;

        await this.usdtCtr.methods.token0().call().then(res => {
          if (res.toString().toLowerCase() === (TETHER.address).toString().toLowerCase()) {
            this.usdweth = 1
          }
        })

        return this.usdtCtr.methods.getReserves().call().then(res => {
          if (this.usdweth === 0) {
            this.ethPrice = (res[1] / 10 ** 6) / (res[0] / 10 ** 18)
          } else {
            this.ethPrice = (res[0] / 10 ** 6) / (res[1] / 10 ** 18)
          }
        }).catch(err => console.log("getUniPairReserves: " + err))
      }
    },
    getTLV: async function () {
      await this.contract.methods.balanceOf(STAKING.address).call().then((res) => {
        this.stakedSize = res / 10 ** 9
      }).catch(err => console.log("getTLV: " + err))

      this.tlv = this.stakedSize * this.thePrice
    },
    getRewardsETH: function () {
      if (this.user) {
          this.stakingContract.methods.pendingRewards(this.poolId, this.user).call().then(res => {
            this.rewardsETH = Web3.utils.toBN(res)
          }).catch(err => console.log("pendingRewards: " + err))
      }
      return this
    },
    getNFTApproval: async function () {
      if (this.user) {
        return this.nftContract.methods.isApprovedForAll(this.user, STAKING.address).call().then(res => {
          this.nftAllowed = res;
        })
      }

      return false
    },
    getApproval: async function () {
      if (this.user) {
        return this.contract.methods.allowance(this.user, STAKING.address).call().then(res => {
          this.allowance = Web3.utils.toBN(res)
          let tmp = Web3.utils.toBN(this.toWei(this.stakeAmount.toString())).add(Web3.utils.toBN(this.userInfo.amount))

          this.approved = (this.allowance !== 0 && (this.allowance).gt(tmp)) ? 1 : 0
        })
      }

      return false
    },
    handleAccountsChanged: function (accounts) {
      if (accounts.length === 0) {
        this.connect();
      } else if (accounts[0] !== this.user) {
        this.user = accounts[0];
      }
    },
    refreshTotalSupply: async function () {
      await this.getUser()
      await this.getNFTSize()
      await this.getDepositedNFTs()
      await this.getPoolInfo()
      await this.getEthPrice()
      this.getRewardsETH()
      await this.getThePrice()
      await this.getNFTApproval()
      // eslint-disable-next-line
      this.getSize().finally(r => {
        let t = this
        setTimeout(function () {
          t.refreshTotalSupply()
        }, 1000);
      });
    },
    connect() {
      window.ethereum
          .request({method: 'eth_requestAccounts'})
          .then(this.handleAccountsChanged)
          .catch((err) => {
            if (err.code === 4001) {
              // EIP-1193 userRejectedRequest error
              // If this happens, the user rejected the connection request.
              console.log('Please connect to MetaMask.');
            } else {
              console.error(err);
            }
          });
    }
  },
  watch: {
    calculator: {
      handler(val) {
        let totalMutiplier = 10000 +
            (val.numdays * (41 + val.nft * 10000));

        this.calc_result = (val.amount * totalMutiplier) / 10000;
        this.multiplier = 0.41 + val.nft * 100

        if (val.nft === 0) {
          this.hardcap = 5000000
        } else if (val.nft === 0.0041) {
          this.hardcap = 10000000
        } else if (val.nft === 0.0082) {
          this.hardcap = 20000000
        } else if (val.nft === 0.0123) {
          this.hardcap = 30000000
        } else if (val.nft === 0.0206) {
          this.hardcap = 50000000
        }

      },
      deep: true
    }
  },
  mounted() {
    this.start()
    window.ethereum.on('accountsChanged', this.handleAccountsChanged)
    window.ethereum.on('chainChanged', this.start)
  }
}
</script>

<style scoped>
.selected {
  border: solid 5px rgb(232, 51, 218);
}

.input-group input {
  font-size: 16px;
  padding: 0.45rem 0.75rem !important;
}

.input-group .btn {
  border-radius: 0.25em !important;
}

.text-lg {
  font-size: 16px;
  line-height: 1.88;
}

label {
  width: 25%;
}

label input {
  position: absolute;
  opacity: 0;
  cursor: pointer;
  height: 0;
  width: 0;
}

label span.btn {
  margin-right: 0;
  background-color: transparent;
  border: solid 1px #39393f;
  border-radius: 0;
  font-size: 12px;
  width: 100%;
}


input:disabled + .btn {
  background-color: #373739;
  color: #ffffff !important;
  cursor: not-allowed;
}

input:checked:not(:disabled) + .btn {
  background-color: rgb(232, 51, 218);
  color: #fff !important;
}
</style>
