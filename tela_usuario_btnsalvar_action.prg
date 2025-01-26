#include "hmg.ch"

declare window tela_usuario

Function tela_usuario_btnsalvar_action

    local cBotaoAcao
    local cCodUsuario
    local cCodUsuario1
    local cNomeUsuario   := ""
    local cAcao          := "X"
    local aDados         := {}
    local aAcessos       := {}
    local nItens         := 0
    local nI             := 0
    local aAcesso        := {}
    local lResultado     := .F.
    local cHash          := ""
    local cSalt          := ""
    local cCombined      := ""
    local cHashCombined  := ""
    local tbSenhaUsuario := ""
    local cSalt1         := ""
    local cSenha1        := ""
    local cSenha2        := ""
    local cConsulta      := ""
    local aResultado     := {}
 
    cBotaoAcao  := getProperty("tela_usuario", "btnSalvar", "Caption")
    cCodUsuario := getProperty("tela_usuario", "tbCodigoUsuario", "Value")
    cCodUsuario1 := cCodUsuario

    AAdd( aDados, getProperty("tela_usuario", "tbNomeUsuario", "Value"))                    // nome
    cNomeUsuario:= getProperty("tela_usuario", "tbNomeUsuario", "Value")
    tbSenhaUsuario := getProperty("tela_usuario", "tbSenhaUsuario", "Value")
    cHash:= hb_SHA512(getProperty("tela_usuario", "tbSenhaUsuario", "Value"))

    cSalt := GenerateRandomSalt(16) // Gera um salt aleatório de 16 caracteres
    
    cCombined := cSalt + cHash
    
    cHashCombined := Lower(hb_SHA512(cCombined))
    
    AAdd( aDados, getProperty("tela_usuario", "tbSaltUsuario" , "Value" ))
    AAdd( aDados, getProperty("tela_usuario", "tbSenhaUsuario" , "Value" ))

    AAdd( aDados, iif( getProperty("tela_usuario", "cbAdministrador", "Value"), "S", "N" )) // admin
    AAdd( aDados, iif( getProperty("tela_usuario", "cbBloqueado", "Value"), "S", "N" ))     // bloqueado
    AAdd( aDados, iif( getProperty("tela_usuario", "cbExcluido", "Value"), "S", "N" ))      // excluido

    nItens := getProperty("tela_usuario", "gAcessosRotinas", "ItemCount")
    for nI := 1 to nItens
        aAcesso := getProperty("tela_usuario", "gAcessosRotinas", "Item", nI)
        AAdd( aAcessos, aAcesso )
    next
    if cBotaoAcao == "Excluir"
        cAcao := "E"
        lResultado := excluiUsuario( cCodUsuario )
    elseif cBotaoAcao == "Salvar"
        cAcao := iif(cCodUsuario == "", "I", "A")
        if cCodUsuario == ""

            lResultado := incluiUsuario( aDados, aAcessos, cSalt, cHashCombined )
              
        else
            if !empty (tbSenhaUsuario)
              
                tbSenhaUsuario := cHashCombined 
                            
                lResultado := alteraUsuario( cCodUsuario, aDados, aAcessos, cSalt, cHashCombined )
            elseif empty (tbSenhaUsuario)
                
                cConsulta  := "SELECT salt, senha FROM usuario WHERE codusuario = " + cCodUsuario
                aResultado := MySQL_ExecQuery(oServer, cConsulta)
                cSalt1     := aResultado[1][1]
                cSenha1    := aResultado[1][2]
                cSenha2    := aDados[3]
                cSalt      := cSalt1
                
                cHashCombined := cSenha1
              
                lResultado := alteraUsuario( cCodUsuario, aDados, aAcessos, cSalt, cHashCombined )
               
            endif
            
        end if
              
    end if

    if lResultado
        doMethod("tela_usuario", "RELEASE")
    end if


Return Nil
