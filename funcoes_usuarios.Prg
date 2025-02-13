#include <hmg.ch>

Function MostraUsuarios()

    local cQuery := "SELECT codusuario, nome, administrador, bloqueado, excluido FROM usuario"
    local aItems    := {}
    local nI        := 0

    aItems := MySQL_ExecQuery( oServer, cQuery )

    doMethod("listausuarios", "gridListaUsuarios", "DeleteAllItems")
    if len(aItems) > 0
        for nI := 1 to len(aItems)
            doMethod("listausuarios", "gridListaUsuarios", "AddItem", aClone(aItems[nI]))
        next
    endif

return NIL

function ValidaUsuario(cUserName, cPassword, cUserCode, lAdmin, cSalt1)

    local lResult        := .F.
    local cCombined      := ""
    local cHashCombined  := ""
    local cHashCombined2 := ""
    local cSenha1        := ""
    local cHash1         := ""   
    local cStoredHash    := ""
    
    local cConsulta := "SELECT codusuario, administrador, salt, senha, bloqueado, excluido FROM usuario WHERE nome = '" + cUserName + "'"
    
    local aItens    := {}

    if ConectaBanco()
        aItens := MySQL_ExecQuery(oServer, cConsulta)
    endif

    if len( aItens ) > 0
        if (aItens[1][5] == "S")
            MsgStop("Usuário teve seu acesso bloqueado! Contate o administrador do sistema!", "Identificação de Usuário")
        elseif (aItens[1][6] == "S")
            MsgStop("Usuário/Senha incorreto!", "Identificação de Usuário")
        else
            lResult   := .T.
            cUserCode := aItens[1][1]
            lAdmin    := (aItens[1][2] == "S")
            cSalt1    := aItens[1][3]
            cSenha1   := aItens[1][4]
            pcSalt1   := cSalt1
            cHash1    := cPassword
            
            cCombined      := cSalt1 + cHash1
            
            cHashCombined  := hb_SHA512(cCombined)
            cHashCombined2 := Lower(hb_SHA512(cCombined))
            cStoredHash    := cSenha1            
            
        endif
        if !empty (cSalt1)            
            
            if cHashCombined == cStoredHash
                lResult   := .T.
                
            else
                lResult   := .F.
            endif
        endif
    else
        MsgStop("Usuário/Senha incorreto!", "Identificação de Usuário")
    endif

return lResult

function BloqueiaUsuario(cUserName)

    local cConsulta := "UPDATE usuario SET bloqueado = 'S' WHERE nome = '" + cUserName + "'"
    local lResult   := .F.

    if ConectaBanco()
        lResult := MySQL_Exec(oServer, cConsulta)
    endif

return lResult

function leDadosUsuario(cCodUsuario)

    local aResultado := {}
    local cSalt1     := ""
    local cSenha1    := ""
    
    local cConsulta  := "SELECT codusuario, nome, salt, senha, administrador, bloqueado, excluido, datacadastro, dataatualizacao FROM usuario WHERE codusuario = " + alltrim(cCodUsuario)
    local aItems     := {}

    aItems := MySQL_ExecQuery(oServer, cConsulta)
    aResultado := aItems[1]
    cSalt1    := aItems[1][3]
    cSenha1   := aItems[1][4]
    pcSalt1   := cSalt1
    
    
return aResultado

function leRotinasPorUsuario(cCodUsuario)

    local aResultado := {}
    local cConsulta  := ""
    local aItems     := {}

    cConsulta := "SELECT rotina.codrotina, rotina.rotina, "
    cConsulta += "(SELECT acesso.acesso FROM acesso "
    cConsulta += " WHERE rotina.codrotina = acesso.codrotina AND acesso.codusuario = " + alltrim(cCodUsuario) + ") AS acessousuario "
    cConsulta += "FROM rotina"

    aResultado := MySQL_ExecQuery(oServer, cConsulta)

return aResultado

function leRotinas()

    local aResultado := {}
    local cConsulta  := ""

    cConsulta  := "SELECT codrotina, rotina FROM rotina"
    aResultado := MySQL_ExecQuery(oServer, cConsulta)

return aResultado

function incluiUsuario( aDados, aAcessos, cSalt, cHashCombined )

    local lResultado := .F.
    local cConsulta  := ""
    local nAcessos   := 0
    local aAcesso    := {}
    local aResultado := {}
    local cCodUsuario
    local nI := 0

    // verificando se o usuário existe
    
    cConsulta  := "SELECT codusuario FROM usuario WHERE nome = '" + aDados[1] + "'"
    aResultado := MySQL_ExecQuery(oServer, cConsulta)

    if len(aResultado) > 0
        MsgStop("Usuário já existe!", "Inclusão de Usuário")
    else
        
        cConsulta  := "INSERT INTO usuario (nome, salt, senha, administrador, bloqueado, excluido) "
        
        aDados[2]  := cSalt
        aDados[3]  := cHashCombined
        
        cConsulta  += "VALUES ('" + aDados[1] + "','" + aDados[2] + "', '" + aDados[3] + "', '" + aDados[4] + "', '" + aDados[5] + "', '" + aDados[6] + "')"
        lResultado := MySQL_Exec(oServer, cConsulta)        

        if lResultado
            cConsulta   := "SELECT codusuario FROM usuario WHERE nome = '" + aDados[1] + "'"
            aResultado  := MySQL_ExecQuery(oServer, cConsulta)
            cCodUsuario := aResultado[1][1]

            nAcessos    := len(aAcessos)
            for nI := 1 to nAcessos
                aAcesso    := aAcessos[nI]
                cConsulta  := "INSERT INTO acesso (codusuario, codrotina, acesso) "
                cConsulta  += "VALUES (" + str(cCodUsuario) + ", " + aAcesso[1] + ", '" + aAcesso[3] + aAcesso[4] + aAcesso[5] + aAcesso[6] + aAcesso[7] + "')"
                lResultado := MySQL_Exec(oServer, cConsulta)
            next
        end if
    end if

    if lResultado
        MsgInfo("Usuário incluído com sucesso", "Inclusão de Usuário")
        MostraUsuarios()
    end if

return lResultado

function alteraUsuario( cCodUsuario, aDados, aAcessos, cSalt, cHashCombined )

    local lResultado := .F.
    local cConsulta  := ""
    local nAcessos   := 0
    local aAcesso    := {}
    local aResultado := {}
    local nI         := 0
    local cSalt1     := ""
    local cSenha1    := ""
    local cSenha2    := ""

    // gravando dados

    cConsulta  := "SELECT salt, senha FROM usuario WHERE codusuario = " + cCodUsuario
    aResultado := MySQL_ExecQuery(oServer, cConsulta)
    cSalt1     := aResultado[1][1]
    cSenha1    := aResultado[1][2]
    cSenha2    := aDados[3]    
    
    cConsulta  := "UPDATE usuario SET "
    aDados[2] := cSalt
    cConsulta  += "salt = '" + aDados[2] + "', "
    aDados[3] := cHashCombined
    cConsulta  += "senha = '" + aDados[3] + "', "
    cConsulta  += "administrador = '" + aDados[4] + "', "
    cConsulta  += "bloqueado = '" + aDados[5] + "', "
    cConsulta  += "excluido = '" + aDados[6] + "' "
    
    cConsulta  += "WHERE codusuario = " + cCodUsuario
    lResultado := MySQL_Exec(oServer, cConsulta)

    if lResultado
        cConsulta   := "DELETE FROM acesso WHERE codusuario = " + cCodUsuario
        lResultado  := MySQL_Exec(oServer, cConsulta)

        nAcessos    := len(aAcessos)
        for nI := 1 to nAcessos
            aAcesso    := aAcessos[nI]
            cConsulta  := "INSERT INTO acesso (codusuario, codrotina, acesso) "
            cConsulta  += "VALUES (" + cCodUsuario + ", " + aAcesso[1] + ", '" + aAcesso[3] + aAcesso[4] + aAcesso[5] + aAcesso[6] + aAcesso[7] + "')"
            lResultado := MySQL_Exec(oServer, cConsulta)
        next
    end if

    if lResultado
        MsgInfo("Usuário alterado com sucesso", "Alteração de Usuário")
        MostraUsuarios()
    end if

return lResultado

function excluiUsuario( cCodUsuario )

    local lResultado := .F.
    local cConsulta  := ""
    local nAcessos   := 0
    local aAcesso    := {}
    local nI         := 0

    // gravando dados

    cConsulta  := "UPDATE usuario SET "
    cConsulta  += "excluido = 'S' "
    cConsulta  += "WHERE codusuario = " + cCodUsuario
    lResultado := MySQL_Exec(oServer, cConsulta)

    if lResultado
        MsgInfo("Usuário excluído com sucesso", "Exclusão de Usuário")
        MostraUsuarios()
    end if

return lResultado

function leUsuarios()

    local cConsulta := "SELECT codusuario, nome, senha, administrador, bloqueado, excluido, datacadastro, dataatualizacao FROM usuario"
    local aItens    := {}

    aItens := MySQL_ExecQuery( oServer, cConsulta )

return aItens

function leAcessoRotinaUsuario(cCodRotina)

    local aResultado := {}
    local cConsulta  := ""
    local cRetorno   := "NNNNN"

    cConsulta := "SELECT acesso FROM acesso "
    cConsulta += "WHERE codrotina = " + alltrim(cCodRotina) + " AND codusuario = " + alltrim(str(pcUserCode)) + " "

    if ConectaBanco()
        aResultado := MySQL_ExecQuery(oServer, cConsulta)
        if ! empty(aResultado)
            cRetorno := aResultado[1][1]
        end if
    end if

return cRetorno // "XXXXX" (CIAER)

function alteraSenha( cSalt2, cNovaSenha )

    local lResultado := .F.
    local cConsulta  := ""
    local cCombined  := ""
    local cHashCombined  := ""
    
    local aDados  := ""

    
    // gravando dados
    
    cConsulta  := "UPDATE usuario SET "
    
    cConsulta  += "salt = '" + alltrim(cSalt2) + "', "
    
    cConsulta  += "senha = '" + alltrim(cNovaSenha) + "' "
    
    cConsulta  += "WHERE codusuario = " + alltrim(str(pcUserCode))
    lResultado := MySQL_Exec(oServer, cConsulta)

    if lResultado
        MsgInfo("Senha alterada com sucesso!", "Alteração de Senha")
    else
        MsgInfo("Senha não alterada!", "Alteração de Senha")
    end if

return lResultado


