//SystemVerilog
module shift_reg_with_vr_handshake (
    input wire clk, reset,
    input wire valid_shift, valid_load,
    input wire serial_in,
    input wire [7:0] parallel_in,
    output wire ready_shift, ready_load,
    output wire serial_out,
    output wire [7:0] parallel_out
);
    reg [7:0] shift_reg;
    reg shift_ready, load_ready;
    
    // 优先级编码控制信号
    wire [1:0] operation = {valid_load, valid_shift};
    
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 8'h00;
            shift_ready <= 1'b1;  // Ready to accept new operations
            load_ready <= 1'b1;   // Ready to accept new operations
        end
        else begin
            // Default values - maintain ready signals high when idle
            shift_ready <= 1'b1;
            load_ready <= 1'b1;
            
            case(operation)
                2'b10, 2'b11: begin  // load优先级高于shift
                    if (load_ready) begin
                        shift_reg <= parallel_in;
                        // Only deassert the load_ready when valid_load is active
                        load_ready <= ~valid_load;
                    end
                end
                2'b01: begin
                    if (shift_ready) begin
                        shift_reg <= {shift_reg[6:0], serial_in};
                        // Only deassert the shift_ready when valid_shift is active
                        shift_ready <= ~valid_shift;
                    end
                end
                default: begin  // 保持当前值
                    shift_reg <= shift_reg;
                end
            endcase
        end
    end
    
    // Valid-Ready握手逻辑
    assign ready_shift = shift_ready;
    assign ready_load = load_ready;
    
    // 直接连接输出
    assign serial_out = shift_reg[7];
    assign parallel_out = shift_reg;
endmodule