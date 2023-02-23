import Vue from 'vue'
import VueRouter from 'vue-router'
import MintingPage from "../views/MintingPage";
// import StakingPage from "../views/StakingPage";

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: MintingPage
  },
  // {
  //   path: '/staking',
  //   name: 'Staking',
  //   component: StakingPage
  // },
]

const router = new VueRouter({
  // mode: 'history',
  base: process.env.BASE_URL,
  routes,
  linkActiveClass: 'active'
})

export default router
