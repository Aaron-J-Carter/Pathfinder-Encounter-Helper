/*
Pathfinder 2e Encounter Helper!

Overall Goal: Make a program to track monsters stat blocks and attacks, making calculating things like MAP and conditions.

First, just making a rig for ^ would be nice, then add in support to put in monster blocks in the program as opposed to in the code. (Possibly insert a .csv file?)



Observations/Ideas: Make a monster struct that holds all needed values
    (Do we even need to add base ability scores? Or are just generally useful skills and given attack bonuses enough?)
    Struct should contain an action counter per turn
    Should have functions calling things like attack that keeps track of MAP inherently based on interal count of 'Attack' actions


Eventually add some overall functions that prompts for things like how many monsters of what kind and such, and include an initiative tracker for monsters and players alike. Then handle a monsters turn by calling appropriat functions on that monster

*/


//Structure for a singular Strike. Will include to hit modifier, damage of all types, and labels for type of attack. Monsters are outfitted with an array of Strikes
struct Strike {

//Strike Parameters
let name: String
let hitMod: Int
let damage: [String : String]
let labels: [String]

//Initializer
init(name: String, hitMod: Int, damage: [String:String], labels: [String]) {
    self.name = name
    self.hitMod = hitMod
    self.damage = damage
    self.labels = labels
}



//Public Functions

//returns Int of number for an attack to hit
func rollHit(attackCount: Int) -> Int {
    if labels.contains("agile") {
        let MAP = 4 * (attackCount - 1)
        return Int.random(in: 1...20) - MAP + hitMod
    }

    let MAP = 5 * (attackCount - 1)
    return Int.random(in: 1...20) - MAP + hitMod
    }



//returns dict of damage number plus damage type
func rollDamage() -> [String:Int] {
    var damageDict: [String:Int] = [:]
    var damageSum: Int = 0
    for (type, number) in damage {
        let splitDamage = damageSplitter(number: number)
        var damageTotal: Int = 0

        for _ in 1...splitDamage[0] {
            damageTotal += Int.random(in: 1...splitDamage[1])
        }

        damageTotal += splitDamage[2]
        damageSum += damageTotal
        damageDict[type] = damageTotal
    }
    damageDict["Total Damage"] = damageSum

    return damageDict
}



//Private Functions


//takes a damage in the form of "xdy+z" and returns [x,y,z]
private func damageSplitter (number: String) -> [Int] {
        let damageSplit = number.split(separator: "d")
        let numberOfDice = Int(damageSplit[0]) ?? 1
        
        var sizeOfDice:Int
        var addBonus: Int = 0

        if damageSplit[1].count > 2 {
            sizeOfDice = Int(damageSplit[1].split(separator: "+")[0]) ?? 1
            addBonus = Int(damageSplit[1].split(separator: "+")[1]) ?? 0
        } 
        
        else {
            sizeOfDice = Int(damageSplit[1].split(separator: "+")[0]) ?? 1
        }
        
        let splitDamage: [Int] = [numberOfDice, sizeOfDice, addBonus]
        
        return splitDamage
}

}

extension Strike: CustomStringConvertible {
    var description: String {
        var _description: String = "\n"
        _description += "Name: \(name) \n"
        _description += "Bonus to hit: \(hitMod) \n"
        _description += "Damage:\n"
        for (number, type) in damage {
            _description += "    \(number) \(type)"
        }
        _description += "\n"
        _description += "Traits: "
        for trait in labels {
            _description += trait + ", "
        }
        _description.removeLast(2)

        return _description
    }

}



//------------------------------------------------------------
//Struct for monster, will contain all base stats needed for combat. Requires Perception, AC, saving throws, Speed, and HP. Ability scores can be added later, along with attacks of type Strike, Extra skills, Name, and Conditions can be added as they occur
struct Monster {

//Monster Parameters
var Str, Dex, Con, Intel, Wis, Cha: Int
var Perception, AC, Fort, Ref, Will, Speed, HP: Int
var Skills, Conditions, Resistances, Weaknesses:  [String : Int]
var Name: String
var Attacks: [Strike]

//Combat Parameters
var currentAttackCount: Int //If first attack, should be 1, second attack, should be 2 ...
var currentActionCount: Int //Similar to ^, starts at 1 and once an action is taken when the count is 3 turn should end


//Non Ability Score Initializer

init(Name: String, Perception: Int, AC: Int, Fort: Int, Ref: Int, Will: Int, Speed: Int, HP: Int) {
    self.Name = Name
    self.Perception = Perception
    self.AC = AC
    self.Fort = Fort
    self.Ref = Ref
    self.Will = Will
    self.Speed = Speed
    self.HP = HP
    Str = 0; Dex = 0; Con = 0; Intel = 0; Wis = 0; Cha = 0
    Skills = [:]; Conditions = [:]; Resistances = [:]; Weaknesses = [:]
    Attacks = []
    currentAttackCount = 1
    currentActionCount = 1
}


//Functions to add ability scores, skills, conditions, and attacks
mutating func setAbilityScores(Str: Int, Dex: Int, Con: Int, Intel: Int, Wis: Int, Cha: Int) -> Void {
    self.Str = Str
    self.Dex = Dex
    self.Con = Con
    self.Intel = Intel
    self.Wis = Wis
    self.Cha = Cha
}

mutating func addAttacks(Attacks: [Strike]) -> Void {
    self.Attacks += Attacks
}

mutating func addSkills(Skills: [String:Int]) -> Void {
    for (name, value) in Skills {
        self.Skills[name] = value
    }
}

mutating func addConditions(Conditions: [String:Int]) -> Void {
    for (name, value) in Conditions {
        self.Conditions[name] = value
    }
}

mutating func setResistancesWeaknesses(Resistances: [String:Int], Weaknesses: [String:Int]) -> Void {
    for (name, value) in Resistances {
        self.Resistances[name] = value
    }
    for (name, value) in Weaknesses {
        self.Weaknesses[name] = value
    }
}


//--------------------------------------------------------------
//Public Functions

//isTurnOver -> Bool. Checks if turn is over and returns true if so
func isTurnOver() -> Bool {
    var actionNumberAdjuster = 0
    for (name, value) in Conditions {
        if name == "Slowed" {
            actionNumberAdjuster -= value
        }
        else if name == "Quickened" {
            actionNumberAdjuster += value
        }
        else if name == "Stunned" || name == "Paralyzed" || name == "Unconscious" {
            return true
        }
    }
    return currentActionCount > 3 + actionNumberAdjuster
}

//Returns True if monster is still Alive
func stillAliveChecker() -> Bool {
    return HP > 0
}

//Calls an attack roll plus damage for given Strike
mutating func strikeAttempt(name: String) -> [String:Int] {
    for candidate in Attacks {
        if name.lowercased() == candidate.name.lowercased() {
            return _strikeAttempt(candidate)
        }
    }

    print("Strike not found in Attack list")
    return ["Error":-1]
}

//Input raw damage given to monster to affect HP| Returns True if Monster is still Alive
mutating func takeDamage(damage: [String: Int]) -> Bool {
    let damageTotal:Int = _takeDamage(damage)
    
    HP -= damageTotal
    return stillAliveChecker()
}

//Resets all action/attack counters, reduces conditions by 1, and deals persistance damage
mutating func endTurn() -> Void {
    
}







//-------------------------------------------------------------
//Private Functions
//Increments attack count
private mutating func attackCountIncrement() -> Void {
    self.currentAttackCount += 1
}

//Increments action count
private mutating func actionCountIncrement() -> Void {
    self.currentActionCount += 1
}


//Body for Strike Attempt function
private mutating func _strikeAttempt(_ strike: Strike) -> [String:Int] {
    var strikeResults: [String:Int] = [:]
    
    strikeResults["Roll to Hit"] = strike.rollHit(attackCount: currentAttackCount) + conditionChecker_Attack(strike)

    let damageResults: [String:Int] = strike.rollDamage()
    for (type, number) in damageResults {
        strikeResults[type] = number
    }
    
    attackCountIncrement()
    actionCountIncrement()

    return strikeResults
}


//Helper for _strikeAttempt. Checks if any conditions affecting the monster affect its roll to hit
private func conditionChecker_Attack(_ strike: Strike) -> Int {
    var conditionAdjuster_Attack = 0
    for (type, value) in Conditions {
        switch type {
            case "Enfeebled":
                if !strike.labels.contains("Finesse") && !strike.labels.contains("Ranged") {
                    conditionAdjuster_Attack -= value
                }
            case "Frightened", "Sickened":
                conditionAdjuster_Attack -= value
            case "Prone":
                conditionAdjuster_Attack -= 2
            case "Clumsy":
                if strike.labels.contains("Finesse") || strike.labels.contains("Ranged") {
                    conditionAdjuster_Attack -= value
                }
            default:
                break
        }
    }
    return conditionAdjuster_Attack
}


//Body for takeDamage, takes damage and returns total damage taken
func _takeDamage(_ damage: [String: Int]) -> Int {
    var damageTotal = 0
    for (type, value) in damage {
        damageTotal += _damageResistanceAndWeaknessChecker(type: type, value: value)
    }
    return damageTotal
}

//Helper for _takeDamage, takes a single damage type and value and returns adjusted amount based on resistances and weaknesses
func _damageResistanceAndWeaknessChecker(type: String, value: Int) -> Int {
    for (Wtype, Wvalue) in Weaknesses {
        if type == Wtype {
            return value + Wvalue
        }
    }

    for (Rtype, Rvalue) in Resistances {
        if type == Rtype && Rvalue >= value {
            return 0
        }

        if type == Rtype {
            return value - Rvalue
        }
    }

    return value
}





}




extension Monster: CustomStringConvertible {
    var description: String {
        let abilityScores = "Str: \(Str), Dex: \(Dex), Con: \(Con), Intel: \(Intel), Wis: \(Wis), Cha: \(Cha) \n"
        let keyAttributes = "\n"
        let attacks = "\n"
        let skills = "\n"
        let conditions = ""


        return "\(Name):\n" + abilityScores + keyAttributes + attacks + skills + conditions
    }
}




//------------------------------------------------------------

var TestMonster = Monster(Name: "Skeleton", Perception: 1, AC: 2, Fort: 3, Ref: 4, Will: 5, Speed: 6, HP: 7)

TestMonster.setAbilityScores(Str: -1, Dex: 3, Con: 0, Intel: -3, Wis: -2, Cha: 0)


var kukri = [
    "Slashing" : "1d6+9",
    "Persistent Bleed" : "2d6",
    "Evil" : "1d4"
]
var testStrike: Strike = Strike(name: "Kukri", hitMod: 18, damage: kukri, labels: ["agile", "trip"])
var testStrike2: Strike = Strike(name: "Kukri2", hitMod: 18, damage: kukri, labels: ["agile", "trip"])

print(TestMonster)
TestMonster.addAttacks(Attacks: [testStrike])
TestMonster.addConditions(Conditions: ["Enfeebled" : 1])
print(TestMonster.strikeAttempt(name: "Kukri"))

print(TestMonster.HP)
print(TestMonster.takeDamage(damage: ["Slashing": 6]))
print(TestMonster.HP)
