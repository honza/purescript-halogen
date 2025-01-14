module Data.Injector
  ( Prism()
  , Injector()
  , inj
  , prj
  , injLE
  , injLC
  , injRE
  , injRC
  ) where

import Prelude (Applicative, (<<<), const, pure, map)

import Data.Const (Const(..), getConst)
import Data.Either (Either(..), either)
import Data.Functor.Coproduct (Coproduct(), coproduct, left, right)
import Data.Identity (Identity(..), runIdentity)
import Data.Maybe (Maybe(..), maybe)
import Data.Maybe.First (First(..), runFirst)
import Data.Profunctor (Profunctor, dimap)
import Data.Profunctor.Choice (Choice)
import qualified Data.Profunctor.Choice as PF

-- | Compatible with `Prism` from `purescript-lens`.
type Prism s t a b = forall p f. (Choice p, Applicative f) => p a (f b) -> p s (f t)

-- | Compatible with `PrismP` from `purescript-lens`.
type Injector s a = Prism a a s s

newtype Tagged s b = Tagged b

instance profunctorTagged :: Profunctor Tagged where
  dimap _ f (Tagged b) = Tagged (f b)

instance choiceTagged :: Choice Tagged where
  left (Tagged b) = Tagged (Left b)
  right (Tagged b) = Tagged (Right b)

unTagged :: forall s b. Tagged s b -> b
unTagged (Tagged b) = b

inj :: forall a b. Injector a b -> a -> b
inj p = runIdentity <<< unTagged <<< p <<< Tagged <<< Identity

prj :: forall a b. Injector a b -> b -> Maybe a
prj p = runFirst <<< getConst <<< p (Const <<< First <<< Just)

prism :: forall s t a b. (b -> t) -> (s -> Either t a) -> Prism s t a b
prism f g = dimap g (either pure (map f)) <<< PF.right

prism' :: forall s a b. (b -> s) -> (s -> Maybe a) -> Prism s s a b
prism' f g = prism f (\s -> maybe (Left s) Right (g s))

injLE :: forall a b. Injector a (Either a b)
injLE = prism' Left (either Just (const Nothing))

injRE :: forall a b. Injector a (Either b a)
injRE = prism' Right (either (const Nothing) Just)

injLC :: forall f g a. Injector (f a) (Coproduct f g a)
injLC = prism' left (coproduct Just (const Nothing))

injRC :: forall f g a. Injector (f a) (Coproduct g f a)
injRC = prism' right (coproduct (const Nothing) Just)
