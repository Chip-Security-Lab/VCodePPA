//SystemVerilog
module karatsuba_multiplier #(parameter WIDTH = 16) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input req,
    output ack,
    output [2*WIDTH-1:0] product
);
    localparam HALF_WIDTH = WIDTH/2;
    
    wire [HALF_WIDTH-1:0] a_high = a[WIDTH-1:HALF_WIDTH];
    wire [HALF_WIDTH-1:0] a_low = a[HALF_WIDTH-1:0];
    wire [HALF_WIDTH-1:0] b_high = b[WIDTH-1:HALF_WIDTH];
    wire [HALF_WIDTH-1:0] b_low = b[HALF_WIDTH-1:0];
    
    wire [2*HALF_WIDTH-1:0] z0 = a_low * b_low;
    wire [2*HALF_WIDTH-1:0] z2 = a_high * b_high;
    wire [2*HALF_WIDTH-1:0] z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2;
    
    assign product = (z2 << WIDTH) + (z1 << HALF_WIDTH) + z0;
    assign ack = req; // 组合逻辑模块，可以立即应答请求
endmodule

module crc16_lookup_table (
    input [7:0] idx,
    input req,
    output ack,
    output reg [15:0] lookup_value
);
    wire [15:0] mult_result;
    wire mult_ack;
    
    karatsuba_multiplier multiplier (
        .a(16'h1021),
        .b({8'h00, idx}),
        .req(req),
        .ack(mult_ack),
        .product(mult_result)
    );
    
    always @(*) begin
        case(idx)
            8'h00: lookup_value = 16'h0000;
            8'h01: lookup_value = 16'h1021;
            8'h02: lookup_value = 16'h2042;
            // ... existing lookup table entries ...
            8'hFD: lookup_value = 16'hB8ED;
            8'hFE: lookup_value = 16'hA9CE;
            8'hFF: lookup_value = 16'h9ACF;
            default: lookup_value = mult_result[15:0];
        endcase
    end
    
    assign ack = mult_ack; // 传递乘法器的应答信号
endmodule

module crc16_calc (
    input [15:0] crc_reg,
    input [15:0] data_in,
    input req,
    output ack,
    output [15:0] next_crc
);
    wire [15:0] lookup_result;
    wire lookup_ack;
    
    crc16_lookup_table lookup_table (
        .idx(crc_reg[15:8] ^ data_in[15:8]),
        .req(req),
        .ack(lookup_ack),
        .lookup_value(lookup_result)
    );
    
    assign next_crc = {crc_reg[7:0], 8'h00} ^ lookup_result;
    assign ack = lookup_ack; // 传递查找表的应答信号
endmodule

module crc16_parallel #(parameter INIT = 16'hFFFF) (
    input clk, 
    input rst_n,
    input req,
    output reg ack,
    input [15:0] data_in,
    output reg [15:0] crc_reg
);
    wire [15:0] next_crc;
    wire calc_ack;
    reg calc_req;
    reg req_r;
    
    // 请求-应答处理状态机
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state, next_state;
    
    crc16_calc calc_unit (
        .crc_reg(crc_reg),
        .data_in(data_in),
        .req(calc_req),
        .ack(calc_ack),
        .next_crc(next_crc)
    );
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            crc_reg <= INIT;
            req_r <= 1'b0;
        end else begin
            state <= next_state;
            req_r <= req;
            
            if (state == CALC && calc_ack)
                crc_reg <= next_crc;
            else if (state == IDLE && !req_r && req)
                req_r <= req;
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        calc_req = 1'b0;
        ack = 1'b0;
        
        case (state)
            IDLE: begin
                if (!req_r && req) begin
                    next_state = CALC;
                end
            end
            CALC: begin
                calc_req = 1'b1;
                if (calc_ack) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                ack = 1'b1;
                if (!req) begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule