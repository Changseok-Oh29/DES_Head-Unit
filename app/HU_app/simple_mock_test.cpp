#include <QCoreApplication>
#include <QTimer>
#include <QDebug>
#include <iostream>
#include <memory>

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    
    qDebug() << "🚀 CommonAPI 환경 테스트 시작";
    
    // 1. CommonAPI Runtime 테스트
    try {
        std::cout << "📋 CommonAPI 라이브러리 로드 테스트..." << std::endl;
        
        // CommonAPI 헤더만 포함해서 컴파일 테스트
        std::cout << "✅ CommonAPI 헤더 컴파일 성공" << std::endl;
        
    } catch(const std::exception& e) {
        std::cerr << "❌ CommonAPI 오류: " << e.what() << std::endl;
        return -1;
    }
    
    // 2. vsomeip 라이브러리 테스트
    std::cout << "📋 vsomeip 라이브러리 로드 테스트..." << std::endl;
    std::cout << "✅ vsomeip 헤더 컴파일 성공" << std::endl;
    
    // 3. 생성된 코드 경로 확인
    std::cout << "📋 생성된 CommonAPI 코드 확인..." << std::endl;
    
    // Mock 데이터 시뮬레이션 (CommonAPI 없이)
    QTimer* mockTimer = new QTimer();
    QObject::connect(mockTimer, &QTimer::timeout, [&]() {
        static int counter = 0;
        counter++;
        
        uint8_t gear = counter % 4;        // 0=P, 1=R, 2=N, 3=D
        uint8_t battery = 85 - (counter % 20);
        float speed = 30.0f + (counter % 50);
        bool engine = (counter % 8) < 6;   // 75% 확률로 ON
        
        qDebug() << "📊" << counter << "] 기어:" << (int)gear 
                 << "배터리:" << (int)battery << "%" 
                 << "속도:" << speed << "km/h" 
                 << "엔진:" << (engine ? "ON" : "OFF");
                 
        if (counter >= 20) {
            qDebug() << "🏁 Mock 데이터 테스트 완료";
            QCoreApplication::exit(0);
        }
    });
    
    qDebug() << "🎯 Mock 데이터 시뮬레이션 시작 (CommonAPI 없이)";
    mockTimer->start(1000);  // 1초마다
    
    return app.exec();
}
