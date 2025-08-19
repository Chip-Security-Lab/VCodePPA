//SystemVerilog
module piso_shifter (
    input wire clk,
    input wire clear,
    input wire valid,
    output reg ready,
    input wire [7:0] parallel_data,
    output wire serial_out
);
    // IEEE 1364-2005 Verilog standard
    
    reg [7:0] shift_data;
    reg shifting;
    reg [2:0] bit_counter;
    
    // 预计算下一个状态，减少关键路径深度
    wire next_ready;
    wire next_shifting;
    wire [2:0] next_counter;
    wire counter_at_end;
    
    // 优化逻辑表达式，减少路径延迟
    assign counter_at_end = (bit_counter == 3'b110);
    assign next_ready = clear ? 1'b1 : 
                        (valid && ready) ? 1'b0 :
                        (shifting && counter_at_end) ? 1'b1 : ready;
    
    assign next_shifting = clear ? 1'b0 :
                           (valid && ready) ? 1'b1 :
                           (shifting && counter_at_end) ? 1'b0 : shifting;
    
    assign next_counter = clear ? 3'b000 :
                          (valid && ready) ? 3'b000 :
                          (shifting) ? bit_counter + 3'b001 : bit_counter;
    
    always @(posedge clk) begin
        ready <= next_ready;
        shifting <= next_shifting;
        bit_counter <= next_counter;
        
        if (clear) begin
            shift_data <= 8'h00;
        end
        else if (valid && ready) begin
            shift_data <= parallel_data;
        end
        else if (shifting) begin
            shift_data <= {shift_data[6:0], 1'b0};
        end
    end
    
    assign serial_out = shift_data[7];
endmodule