<template>
  <b-container class="py-3">
    <header>
      <div class="d-flex flex-column flex-md-row align-items-center pb-3 mb-4">
        <a href="/" class="d-flex align-items-center text-dark text-decoration-none d-block d-sm-block d-md-none">
          <img src="/images/logo-mouseworm-01.png" alt="Mouseworm Logo" width="300">
        </a>
        <nav class="d-inline-flex mt-2 mt-md-0 ms-md-auto ml-md-auto">
          <button class="btn btn-connect me-2" type="button" v-if="user === null" @click="connect">Connect yo wallet</button>
        </nav>
      </div>
      <div class="pricing-header p-3 pb-md-4 mx-auto text-center">
      </div>
    </header>
    <main class="nft">
      <b-row class="relative">
        <b-col cols="12" class="col-md logo-title">
          <b-img src="/images/title-mouseworm-nfts.svg" alt="Mouseworm Logo"></b-img>
          <div class="card mainBG six-hands-brush txt-lg px-5 px-lg-5 px-xxl-5 py-3 m-4 m-md-0">
            <p class="pe-1 pe-md-3 pe-lg-5">Mint an NFT from our exclusive collection.
              Only <strong>100 will be minted</strong> and they will receive rewards going forward.</p>
          </div>
          <div class="wormie"><img src="/images/icon-wormie.png" width="100"></div>
        </b-col>
        <div class="col-6 col-md-6 logoBG">
          <img src="/images/logo-mouseworm-01.png" alt="Mouseworm Logo" class="d-none d-md-block d-lg-block d-md-block">
        </div>
      </b-row>
      <div class="container">
        <div class="row">
          <div class="col-12">
            <b-tabs pills justified class="nav-fill">
              <b-tab title="Mint" active class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="6" class="card py-4 py-lg-5 my-lg-5 text-center ms-1 ms-lg-5 mint">
                    <b-container v-if="isPaused !== false">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          Sale not started yet
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else-if="size <= requiredSize">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          You have to hold at least {{ fromWei(requiredSize,6) }} MouseWorm to mint {{ size }}
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else-if="maxNFTAmount <= sizeNFT">
                      <b-row class="text-center txt-md py-5">
                        <b-col cols="12">
                          You already minted maximum amount of NFTs
                        </b-col>
                      </b-row>
                    </b-container>
                    <b-container v-else>
                      <b-row>
                        <b-col cols="6" class="ps-0 ps-md-5 ps-lg-5 mint-amount">
                          <b-form-spinbutton name="amount" v-model="amount" min="1"
                                             :max="maxNFTAmount - sizeNFT" style="border: 5px solid #AB2E9A !important;"></b-form-spinbutton>
                        </b-col>
                        <b-col cols="6" class=" text-right pe-1 pe-md-5 pe-lg-5">
                          <vue-loading-button class="btn btn-mint" :style="false" :loading="mintLoading" @click.native="mint">Mint</vue-loading-button>
                        </b-col>
                      </b-row>
                      <b-row class="text-center txt-md pt-2 pt-lg-5">
                        <b-col>
                          Cost to Mint: {{ fromWei(price.muln(amount), 18) }} ETH
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                  <b-col cols="12" lg="5" class="txt-lg six-hands-brush mt-5 pt-lg-5 ps-lg-5">
                    <b-row>
                      <b-col cols="6" class="dk-blue">Minted:</b-col>
                      <b-col cols="6" class="white">{{ sizeNFT }} / {{ maxNFTAmount }}</b-col>
                    </b-row>
                    <b-row>
                      <b-col cols="6" class="dk-blue">Total Minted:</b-col>
                      <b-col cols="6" class="white">{{ minted }} / 100</b-col>
                    </b-row>
                  </b-col>
                </b-row>
              </b-tab>
              <b-tab title="Stake" class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="12" class="card py-4 py-lg-5 my-lg-5 text-center ms-1 ms-lg-5 mint">
                    <b-container>
                      <b-row class="text-center txt-md">
                        <b-col>
                          Coming soon
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                </b-row>
              </b-tab>
              <b-tab title="Rewards" class="dk-blue">
                <b-row class="pt-md-5">
                  <b-col cols="12" lg="12" class="card py-4 py-lg-5 my-lg-5 text-center ms-1 ms-lg-5 mint">
                    <b-container>
                      <b-row class="text-center txt-md">
                        <b-col>
                          Coming soon
                        </b-col>
                      </b-row>
                    </b-container>
                  </b-col>
                </b-row>
              </b-tab>
            </b-tabs>
          </div>
        </div>
      </div>
    </main>
  </b-container>
</template>

<style scoped>
.form-control.b-form-spinbutton, .form-control.b-form-spinbutton input, .form-control.b-form-spinbutton:focus, .form-control.b-form-spinbutton:active, .form-control.b-form-spinbutton.focus {
  background-color: transparent !important;
  color: #000 !important;
  box-shadow: none !important;
  border: 1px solid #fff !important;
}

.b-form-spinbutton .btn {
  color: #000000 !important;
}

.text-lg {
  font-size: 24px;
  font-weight: bold;
}
</style>

<script>
import Web3 from "web3"
import NFT from "@/helper/contracts/nft"
import MW from "@/helper/contracts/mw"
import VueLoadingButton from "vue-loading-button";


export default {
  name: "Minting",
  components: {VueLoadingButton},
  data: function () {
    return {
      isObservationEnabled: false,
      user: null,
      nftContract: null,
      contract: null,
      showAlert: false,
      mintLoading: false,
      isRevealed: false,
      amount: 1,
      price: Web3.utils.toBN(0),
      minted: Web3.utils.toBN(0),
      isPaused: false,
      requiredSize: Web3.utils.toBN("100000000"),
      userNFTs: [],
      size: Web3.utils.toBN(0),
      sizeNFT: 0,
      maxNFTAmount: 0,
      maxSupply: Web3.utils.toBN(0)
    }
  },
  methods: {
    beautifyWallet: function (address) {
      return address.slice(0, 6) + '...' + address.slice(-6)
    },
    format: function (number) {
      return new Intl.NumberFormat('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
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

      //connect to the contract
      let web3js = new Web3(provider);
      this.nftContract = new web3js.eth.Contract(NFT.abi, NFT.address);
      this.contract = new web3js.eth.Contract(MW.abi, MW.address);

      web3js.eth.getChainId().then((id) => {
        if (id != MW.chain) {
          this.showAlert = true
        } else {
          this.showAlert = false
          //recursively get total supply
          const refreshTotalSupply = () => {
            this.getSize()
            this.getSaleState()
            this.getPrice()
            this.getNFTSize()
            this.getMaxNFTAmount()
            this.getMaxSupply()
            this.getUserNFTs()
            this.getIsRevealed()
            // eslint-disable-next-line
            this.getTotalSupply().finally(r => {
              setTimeout(refreshTotalSupply, 500);
            });
          }

          refreshTotalSupply();
        }
      });
    },
    fromWei: function (number, num) {
      if (typeof number === "undefined") {
        return 0;
      }
      let type = 'ether'

      if(num === 6) {
        type = "picoether"
      }

      return Web3.utils.fromWei(number, type)
    },
    toWei: function (number, num) {

      let type = 'ether'

      if(num === 6) {
        type = "picoether"
      }

      return Web3.utils.toWei(number, type)
    },
    getTotalSupply: function () {
      return this.nftContract.methods.totalSupply().call().then(res => {
        this.minted = Web3.utils.toBN(res)
      });
    },
    getIsRevealed: function () {
      return this.nftContract.methods._isRevealed().call().then(res => {
        this.isRevealed = res
      });
    },
    getSaleState: function () {
      this.nftContract.methods._paused().call().then(res => {
        this.isPaused = res
      })
    },
    getPrice: function () {
      if (this.user != null) {
        this.nftContract.methods.getPrice().call().then(res => {
          this.price = Web3.utils.toBN(res)
        })
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
    getNFTSize: function () {
      if (this.user !== null) {
        this.nftContract.methods.balanceOf(this.user).call().then(res => {
          this.sizeNFT = parseFloat(res)
        })
      }
    },
    getUserNFTs: function () {
      if (this.user !== null && this.sizeNFT > 0) {
        this.nftContract.methods.walletOfOwner(this.user).call().then(res => {
          this.userNFTs = res
        })
      }
    },
    getMaxNFTAmount: function () {
      if (this.user !== null) {
        this.nftContract.methods._maxNFTAmount().call().then(res => {
          this.maxNFTAmount = parseFloat(res)
        })
      }
    },
    getMaxSupply: function () {
      if (this.user !== null) {
        this.nftContract.methods._maxSupply().call().then(res => {
          this.maxSupply = Web3.utils.toBN(res)
        })
      }
    },
    handleAccountsChanged: function (accounts) {
      if (accounts.length === 0) {
        this.connect();
      } else if (accounts[0] !== this.user) {
        this.user = accounts[0];
      }
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
    },
    mint() {
      let eth = this.amount * this.price;
      var that = this

      that.mintLoading = true;

      return this.nftContract.methods.mint(this.amount)
          .send({from: this.user, value: eth})
          .on("receipt", function () {
            that.mintLoading = false;
            console.log("Mint successful")
          })
          .on("error", function () {
            that.mintLoading = false;
            console.log("Mint failed")
          });
    }
  },
  mounted() {
    this.start()
    window.ethereum.on('accountsChanged', this.handleAccountsChanged);
    window.ethereum.on('chainChanged', this.start);
  }
}
</script>