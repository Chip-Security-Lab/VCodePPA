//SystemVerilog
module quad_clock_gen(
    input clock_in,
    input reset,
    output reg clock_0,
    output reg clock_90,
    output reg clock_180,
    output reg clock_270
);
    reg [1:0] phase_counter;
    reg [3:0] clock_decode;
    
    always @(posedge clock_in or posedge reset) begin
        if (reset)
            phase_counter <= 2'b00;
        else
            phase_counter <= phase_counter + 1'b1;
    end
    
    // 使用独立的时序块进行时钟解码，减少关键路径长度
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            clock_decode <= 4'b0001; // 复位时只有clock_0有效
        end else begin
            // 使用移位寄存器结构代替比较逻辑，降低逻辑复杂度
            clock_decode <= {clock_decode[2:0], clock_decode[3]};
        end
    end
    
    // 使用解码后的信号直接驱动输出时钟，避免组合逻辑延迟
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            clock_0 <= 1'b0;
            clock_90 <= 1'b0;
            clock_180 <= 1'b0;
            clock_270 <= 1'b0;
        end else begin
            clock_0 <= clock_decode[0];
            clock_90 <= clock_decode[1];
            clock_180 <= clock_decode[2];
            clock_270 <= clock_decode[3];
        end
    end
endmodule