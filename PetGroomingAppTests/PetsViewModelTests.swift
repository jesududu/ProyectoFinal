import XCTest
@testable import PetGroomingApp


final class PetsViewModelTests: XCTestCase {

    var sut: PetsViewModel! // System Under Test
    var mockDataService: MockPetDataService!

    // Se ejecuta ANTES de cada prueba
    override func setUpWithError() throws {
        // 1. Inicializa el mock con el comportamiento por defecto (éxito)
        mockDataService = MockPetDataService()
        
        // 2. Inyecta el mock al ViewModel
        sut = PetsViewModel(dataService: mockDataService)
    }

    // Se ejecuta DESPUÉS de cada prueba
    override func tearDownWithError() throws {
        sut = nil
        mockDataService = nil
    }

    // MARK: - fetchPets() Tests

    func testFetchPets_Success() throws {
        // Given (Configuración)
        let expectedPets = [Pet(id: "1", name: "Max", breed: "Labrador"), Pet(id: "2", name: "Bella", breed: "Poodle")]
        mockDataService.mockPets = expectedPets
        
        // Creamos una expectativa para esperar que la operación asíncrona termine
        let expectation = XCTestExpectation(description: "Fetch pets completado")
        
        // When (Acción)
        XCTAssertFalse(sut.isLoading, "Debe ser falso antes de llamar")
        sut.fetchPets()
        XCTAssertTrue(sut.isLoading, "Debe ser verdadero después de llamar")

        // Then (Verificación)
        
        // Usamos un Timer para esperar el resultado asíncrono en el main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isLoading, "Debe ser falso después de completarse")
            XCTAssertTrue(self.mockDataService.fetchPetsCalled, "El mock service debe ser llamado")
            XCTAssertNil(self.sut.error, "No debe haber error")
            
            // Verifica que los pets del ViewModel sean los esperados
            XCTAssertEqual(self.sut.pets.count, 2, "Debe haber 2 mascotas")
            XCTAssertEqual(self.sut.pets, expectedPets, "Las mascotas deben coincidir")
            
            expectation.fulfill() // Marca la expectativa como cumplida
        }
        
        // Espera a que la expectativa se cumpla
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchPets_Failure() throws {
        // Given
        mockDataService.shouldSucceed = false // Forzamos el fallo
        let expectation = XCTestExpectation(description: "Fetch pets fallido")
        
        // When
        sut.fetchPets()

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.sut.isLoading, "Debe ser falso después de completarse")
            XCTAssertTrue(self.mockDataService.fetchPetsCalled, "El mock service debe ser llamado")
            
            // Verifica que se haya capturado el error
            XCTAssertNotNil(self.sut.error, "Debe haber un error")
            XCTAssertTrue(self.sut.error is DataError, "El error debe ser del tipo DataError")
            XCTAssertTrue(self.sut.pets.isEmpty, "La lista de pets debe estar vacía")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - createPet() Tests
    
    func testCreatePet_Success() throws {
        // Given
        let newPet = Pet(id: "3", name: "Lola", breed: "Dachshund")
        
        // Necesitamos 2 expectativas: 1 para createPet y 1 para la posterior fetchPets()
        let createExpectation = XCTestExpectation(description: "Create pet completado")
        let fetchExpectation = XCTestExpectation(description: "Fetch pets para refrescar completado")
        
        // Prepara el mock para que fetchPets devuelva la nueva lista después de crear
        let expectedPetsAfterCreation = [newPet]
        // Controlamos cuándo se cumplen las expectativas
        mockDataService.fetchPets = { completion in
            self.mockDataService.fetchPetsCalled = true
            completion(.success(expectedPetsAfterCreation))
            fetchExpectation.fulfill() // Fulfilla la segunda expectativa
        }
        
        // When
        sut.createPet(pet: newPet)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockDataService.createPetCalled, "El mock service debe llamar a createPet")
            XCTAssertEqual(self.mockDataService.petToCreate, newPet, "La mascota pasada al mock debe coincidir")
            XCTAssertNil(self.sut.error, "No debe haber error")
            
            // Ahora esperamos la llamada asíncrona a fetchPets()
            createExpectation.fulfill()
        }
        
        // Esperamos ambas expectativas
        wait(for: [createExpectation, fetchExpectation], timeout: 2.0)
        
        // Verifica el estado final después de que se completa fetchPets
        XCTAssertEqual(sut.pets, expectedPetsAfterCreation, "La lista de pets debe haberse actualizado")
    }
    
    func testCreatePet_Failure() throws {
        // Given
        mockDataService.shouldSucceed = false
        let newPet = Pet(id: "4", name: "Rocky", breed: "Beagle")
        let expectation = XCTestExpectation(description: "Create pet fallido")
        
        // When
        sut.createPet(pet: newPet)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockDataService.createPetCalled, "El mock service debe llamar a createPet")
            
            // Verifica que se haya capturado el error de creación
            XCTAssertNotNil(self.sut.error, "Debe haber un error")
            XCTAssertTrue(self.sut.error is DataError, "El error debe ser del tipo DataError")
            XCTAssertFalse(self.mockDataService.fetchPetsCalled, "fetchPets no debe ser llamado")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
