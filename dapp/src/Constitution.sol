pragma solidity ^0.4.13;

import "zeppelin/contracts/ownership/Ownable.sol";


// A Constitution is created when the DBVN is deployed
// The DBVN is the owner, but it can add editors (other DBVNs...)


contract Constitution is Ownable {
  mapping (address => bool) public editorIndex;

  uint public numArticles;
  Article[] public allArticles;

  struct Article {
    string summary;
    string reference;

    address addedBy;

    bool isValid;

    uint createdAt;
    uint repealedAt;
  }

  event EditorAdded(address indexed editor);
  event EditorRemoved(address indexed editor);

  event ArticleAdded(uint indexed articleId, address indexed editor);
  event ArticleRepealed(uint indexed articleId, address indexed editor);

  modifier onlyEditor {
    require(isEditor(msg.sender));
    _;
  }

  function Constitution() {
    addEditor(msg.sender); // Owner should be an editor
  }

  // Owner functions

  function addEditor(address editor) onlyOwner {
    require(!isEditor(editor));

    editorIndex[editor] = true;

    EditorAdded(editor);
  }

  function removeEditor(address editor) onlyOwner {
    require(isEditor(editor));

    editorIndex[editor] = false;

    EditorRemoved(editor);
  }

  // Editors functions

  function addArticle(string articleSummary, string articleReference) onlyEditor returns (uint articleId) {
    articleId = allArticles.length++;
    numArticles = allArticles.length;

    allArticles[articleId] = Article({summary: articleSummary, reference: articleReference, addedBy: msg.sender, isValid: true, createdAt: now, repealedAt: 0});

    ArticleAdded(articleId, msg.sender);
  }

  function repealArticle(uint articleId) onlyEditor {
    require(allArticles[articleId].isValid);

    allArticles[articleId].isValid = false;
    allArticles[articleId].repealedAt = now;

    ArticleRepealed(articleId, msg.sender);
  }

  // Some utils

  function isEditor(address editor) constant returns (bool isEditor) {
    isEditor = editorIndex[editor];
  }
}
