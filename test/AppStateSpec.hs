module AppStateSpec where

import Test.Hspec ( describe, it, shouldBe, Spec )
import Zipper (Zipper(..))
import Task ( Event(Start), Task(Task, tag, description, history) )
import AppState
    ( activateTask, addTask, deleteTask, AppState )
import StateM (getLocalTime)

spec :: Spec
spec = do
    
    let task0 = Task { tag = "0", description = "zero",  history = [] }
        task1 = Task { tag = "1", description = "one",   history = [] }
        task2 = Task { tag = "2", description = "two",   history = [] }
        task3 = Task { tag = "3", description = "three", history = [] }
        task4 = Task { tag = "4", description = "four",  history = [] }
        empty = Empty :: AppState

    describe "deleteTask" $ do

        it "should remove a task" $ do

            deleteTask "0" (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task2, task3, task4] task1 []
            deleteTask "0" (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task2, task3, task4] task1 []
            deleteTask "0" (Zipper [task3, task4] task2 [task1])   `shouldBe` Zipper [task3, task4] task2 [task1]
            deleteTask "0" (Zipper [task4] task3 [task2, task1])   `shouldBe` Zipper [task4] task3 [task2, task1]
            deleteTask "0" (Zipper [] task4 [task3, task2, task1]) `shouldBe` Zipper [] task4 [task3, task2, task1]
            deleteTask "0" empty                                     `shouldBe` empty
            deleteTask "0" (Zipper [] task2 [])                    `shouldBe` Zipper [] task2 []
            deleteTask "2" (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task3, task4] task1 []
            deleteTask "2" (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task3, task4] task1 []
            deleteTask "2" (Zipper [task3, task4] task2 [task1])   `shouldBe` Zipper [task3, task4] task1 []
            deleteTask "2" (Zipper [task3, task4] task2 [])        `shouldBe` Zipper [task4] task3 []
            deleteTask "2" (Zipper [task4] task3 [task2, task1])   `shouldBe` Zipper [task4] task3 [task1]
            deleteTask "2" (Zipper [] task4 [task3, task2, task1]) `shouldBe` Zipper [] task4 [task3, task1]
            deleteTask "2" (Zipper [] task2 [])                    `shouldBe` empty

    describe "addTask" $ do

        it "should add at active position" $ do

            addTask task0 empty                                   `shouldBe` Zipper [] task0 []
            addTask task0 (Zipper [] task0 [])                    `shouldBe` Zipper [] task0 []
            addTask task0 (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task2, task3, task4] task0 [task1]
            addTask task0 (Zipper [task3, task4] task2 [task1])   `shouldBe` Zipper [task3, task4] task0 [task2, task1]
            addTask task0 (Zipper [task4] task3 [task2, task1])   `shouldBe` Zipper [task4] task0 [task3, task2, task1]
            addTask task0 (Zipper [] task4 [task3, task2, task1]) `shouldBe` Zipper [] task0 [task4, task3, task2, task1]
            addTask task2 (Zipper [task2, task3, task4] task1 []) `shouldBe` Zipper [task2, task3, task4] task1 []
            addTask task2 (Zipper [task3, task4] task2 [task1])   `shouldBe` Zipper [task3, task4] task2 [task1]
            addTask task2 (Zipper [task4] task3 [task2, task1])   `shouldBe` Zipper [task4] task3 [task2, task1]
            addTask task2 (Zipper [] task4 [task3, task2, task1]) `shouldBe` Zipper [] task4 [task3, task2, task1]
            
    describe "activateTask" $ do

        it "should return Zipper correctly activated" $ do

            let ref = Just (Zipper [task1, task2, task3, task4] task0 [])

            activateTask "0" (Zipper [task1, task2, task3, task4] task0 []) `shouldBe` ref
            activateTask "0" (Zipper [task2, task3, task4] task1 [task0])   `shouldBe` ref
            activateTask "0" (Zipper [task3, task4] task2 [task1, task0])   `shouldBe` ref
            activateTask "0" (Zipper [task4] task3 [task2, task1, task0])   `shouldBe` ref
            activateTask "0" (Zipper [] task4 [task3, task2, task1, task0]) `shouldBe` ref

        it "should return Zipper correctly activated even from mid term" $ do

            let ref = Just (Zipper [task3, task4] task2 [task1, task0])

            activateTask "2" (Zipper [task1, task2, task3, task4] task0 []) `shouldBe` ref
            activateTask "2" (Zipper [task2, task3, task4] task1 [task0])   `shouldBe` ref
            activateTask "2" (Zipper [task3, task4] task2 [task1, task0])   `shouldBe` ref
            activateTask "2" (Zipper [task4] task3 [task2, task1, task0])   `shouldBe` ref
            activateTask "2" (Zipper [] task4 [task3, task2, task1, task0]) `shouldBe` ref

        it "should return Zipper correctly activated even from end" $ do

            let ref = Just (Zipper [] task4 [task3, task2, task1, task0])

            activateTask "4" (Zipper [task1, task2, task3, task4] task0 []) `shouldBe` ref
            activateTask "4" (Zipper [task2, task3, task4] task1 [task0])   `shouldBe` ref
            activateTask "4" (Zipper [task3, task4] task2 [task1, task0])   `shouldBe` ref
            activateTask "4" (Zipper [task4] task3 [task2, task1, task0])   `shouldBe` ref
            activateTask "4" (Zipper [] task4 [task3, task2, task1, task0]) `shouldBe` ref

        it "should stick to activated already" $ do

            activateTask "0" (Zipper [] task0 [])      `shouldBe` Just (Zipper [] task0 [])
            activateTask "0" (Zipper [task1] task0 []) `shouldBe` Just (Zipper [task1] task0 [])

        it "can't activate empty" $ do

            activateTask "0" empty `shouldBe` Nothing

        it "should fail it task doesn't exists" $ do

            activateTask "5" (Zipper [task1, task2, task3, task4] task0 []) `shouldBe` Nothing
            activateTask "5" (Zipper [task2, task3, task4] task1 [task0])   `shouldBe` Nothing
            activateTask "5" (Zipper [task3, task4] task2 [task1, task0])   `shouldBe` Nothing
            activateTask "5" (Zipper [task4] task3 [task2, task1, task0])   `shouldBe` Nothing
            activateTask "5" (Zipper [] task4 [task3, task2, task1, task0]) `shouldBe` Nothing
            activateTask "3" (Zipper [task1] task0 [])                      `shouldBe` Nothing

    describe "read . show" $ do

        it "should be an identity" $ do
            
            timeStamp <- getLocalTime
            let task t = Task { 
                      tag = t
                    , description = "details" ++ t
                    , history = [(timeStamp, Start)] 
                }
                appState = Zipper [task "three", task "four"] (task "two") [task "one", task "zero"]
                newAppState = read (show appState) :: AppState
    
            newAppState `shouldBe` appState

    describe "an empty application state" $ do

        it "should roundtrip as well" $ do

            let newAppState = read (show empty) :: AppState
    
            newAppState `shouldBe` empty

        it "should serialize" $ do
    
            show empty `shouldBe` "Empty"