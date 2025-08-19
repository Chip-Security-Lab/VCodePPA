//SystemVerilog
module MuxInputShift #(parameter W=4) (
    input clk,
    input [1:0] sel,
    input [W-1:0] d0, d1, d2, d3,
    output reg [W-1:0] q
);
    // 使用IEEE 1364-2005 Verilog标准
    // 优化比较链和移位操作
    reg [W-1:0] data_in;
    reg shift_left;
    reg load_full;
    
    always @(*) begin
        // 默认值
        data_in = d0;
        shift_left = 1'b0;
        load_full = 1'b0;
        
        case (sel)
            2'b00: data_in = d0;
            2'b01: data_in = d1;
            2'b10: begin
                data_in = d2;
                shift_left = 1'b1;
            end
            2'b11: begin
                data_in = d3;
                load_full = 1'b1;
            end
        endcase
    end
    
    always @(posedge clk) begin
        if (load_full)
            q <= data_in;
        else if (shift_left)
            q <= {data_in, q[W-1:1]};
        else
            q <= {q[W-2:0], data_in[0]};
    end
endmodule