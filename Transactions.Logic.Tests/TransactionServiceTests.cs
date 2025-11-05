using AutoFixture;
using Moq;
using Transactions.Core;
using Transactions.Repository.Abstractions;

namespace Transactions.Logic.Tests
{
  public class TransactionsServiceTests
  {
    private readonly Mock<ITransactionsRepository> _repositoryMock;
    private readonly TransactionsService _service;

    private readonly Fixture _fixture = new ();

    public TransactionsServiceTests()
    {
      _repositoryMock = new Mock<ITransactionsRepository>();
      _service = new TransactionsService(_repositoryMock.Object);
    }

    [Fact]
    public async Task ShouldCreateTransaction_AndReturnCreatedTransactionId()
    {
      // Given
      var transaction = _fixture.Create<Transaction>();
      var expectedTransactionId = 42L;

      _repositoryMock
        .Setup(r => r.InsertAsync(transaction))
        .ReturnsAsync(expectedTransactionId);

      // When
      var result = await _service.CreateTransactionAsync(transaction);

      // Then
      Assert.Equal(expectedTransactionId, result.Id);

      _repositoryMock.Verify(r => r.InsertAsync(transaction), Times.Once);
    }

    [Theory]
    [InlineData(4, true)]
    [InlineData(7, false)]
    public async Task ShouldUpdateTransactionsStatesByTime_AndReturnEvenOrOddFlag(int currentSeconds, bool expectedIsEven)
    {
      // Given
      _repositoryMock
        .Setup(r => r.UpdateStatesByConditionAsync(
          TransactionState.Processed,
          TransactionState.Pending,
          expectedIsEven))
        .Returns(Task.CompletedTask);

      // When
      var result = await _service.UpdateTransactionsStatesByTimeAsync(currentSeconds);

      // Then
      Assert.Equal(expectedIsEven, result.IsEvenUpdate);

      _repositoryMock.Verify(r => r.UpdateStatesByConditionAsync(
        TransactionState.Processed,
        TransactionState.Pending,
        expectedIsEven), Times.Once);
    }
  }
}