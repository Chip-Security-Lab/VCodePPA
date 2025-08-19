//SystemVerilog
module baugh_wooley_multiplier (
    input clk,
    input rst_n,
    input valid,
    output ready,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result
);
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    wire [15:0] a_pos = {1'b0, a[14:0]};
    wire [15:0] b_pos = {1'b0, b[14:0]};
    wire a_sign = a[15];
    wire b_sign = b[15];
    
    wire [15:0] pp0 = a_pos & {16{b_pos[0]}};
    wire [15:0] pp1 = a_pos & {16{b_pos[1]}};
    wire [15:0] pp2 = a_pos & {16{b_pos[2]}};
    wire [15:0] pp3 = a_pos & {16{b_pos[3]}};
    wire [15:0] pp4 = a_pos & {16{b_pos[4]}};
    wire [15:0] pp5 = a_pos & {16{b_pos[5]}};
    wire [15:0] pp6 = a_pos & {16{b_pos[6]}};
    wire [15:0] pp7 = a_pos & {16{b_pos[7]}};
    wire [15:0] pp8 = a_pos & {16{b_pos[8]}};
    wire [15:0] pp9 = a_pos & {16{b_pos[9]}};
    wire [15:0] pp10 = a_pos & {16{b_pos[10]}};
    wire [15:0] pp11 = a_pos & {16{b_pos[11]}};
    wire [15:0] pp12 = a_pos & {16{b_pos[12]}};
    wire [15:0] pp13 = a_pos & {16{b_pos[13]}};
    wire [15:0] pp14 = a_pos & {16{b_pos[14]}};
    wire [15:0] pp15 = a_pos & {16{b_pos[15]}};
    
    wire [15:0] sign_correction = {16{a_sign}} & b_pos;
    wire [15:0] sign_correction2 = {16{b_sign}} & a_pos;
    
    wire [31:0] sum1 = {pp15, pp14, pp13, pp12, pp11, pp10, pp9, pp8, pp7, pp6, pp5, pp4, pp3, pp2, pp1, pp0};
    wire [31:0] sum2 = {sign_correction, 16'b0};
    wire [31:0] sum3 = {sign_correction2, 16'b0};
    
    assign ready = (state == IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            result <= 32'h0;
        end else begin
            case(state)
                IDLE: begin
                    if (valid) begin
                        state <= CALC;
                    end
                end
                CALC: begin
                    result <= sum1 + sum2 + sum3 + (a_sign & b_sign ? 32'h00010000 : 32'h0);
                    state <= DONE;
                end
                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

module decoder_multi_protocol (
    input clk,
    input rst_n,
    input valid,
    output ready,
    input [1:0] mode,
    input [15:0] addr,
    input [15:0] multiplier_a,
    input [15:0] multiplier_b,
    output reg [7:0] select,
    output [31:0] mult_result
);
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    wire mult_ready;
    reg mult_valid;
    reg [15:0] a_reg;
    reg [15:0] b_reg;

    baugh_wooley_multiplier bw_mult (
        .clk(clk),
        .rst_n(rst_n),
        .valid(mult_valid),
        .ready(mult_ready),
        .a(a_reg),
        .b(b_reg),
        .result(mult_result)
    );

    assign ready = (state == IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            select <= 8'h00;
            mult_valid <= 1'b0;
            a_reg <= 16'h0;
            b_reg <= 16'h0;
        end else begin
            case(state)
                IDLE: begin
                    if (valid) begin
                        a_reg <= multiplier_a;
                        b_reg <= multiplier_b;
                        mult_valid <= 1'b1;
                        state <= CALC;
                    end
                end
                CALC: begin
                    mult_valid <= 1'b0;
                    if (mult_ready) begin
                        case(mode)
                            2'b00: select <= (addr[15:12] == 4'h1) ? 8'h01 : 8'h00;
                            2'b01: select <= (addr[7:5] == 3'b101) ? 8'h02 : 8'h00;
                            2'b10: select <= (addr[11:8] > 4'h7) ? 8'h04 : 8'h00;
                            default: select <= 8'h00;
                        endcase
                        state <= DONE;
                    end
                end
                DONE: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule