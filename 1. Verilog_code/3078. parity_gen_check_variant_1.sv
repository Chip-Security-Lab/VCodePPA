//SystemVerilog
module parity_gen_check(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire parity_type,
    input wire gen_check_n,
    output reg parity_bit,
    output reg error
);
    localparam IDLE=4'b0000, COMPUTE1=4'b0001, COMPUTE2=4'b0010, 
               COMPUTE3=4'b0011, OUTPUT=4'b0100, ERROR_STATE=4'b0101;
    reg [3:0] state, next;
    reg [7:0] data_reg;
    reg [1:0] computed_parity_low, computed_parity_mid, computed_parity_high;
    reg [1:0] computed_parity_stage1, computed_parity_stage2;
    reg computed_parity;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'd0;
            parity_bit <= 1'b0;
            error <= 1'b0;
            computed_parity_low <= 2'd0;
            computed_parity_mid <= 2'd0;
            computed_parity_high <= 2'd0;
            computed_parity_stage1 <= 2'd0;
            computed_parity_stage2 <= 2'd0;
            computed_parity <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    error <= 1'b0;
                    if (data_valid)
                        data_reg <= data_in;
                end
                COMPUTE1: begin
                    computed_parity_low <= ^data_reg[1:0];
                    computed_parity_mid <= ^data_reg[3:2];
                    computed_parity_high <= ^data_reg[5:4];
                end
                COMPUTE2: begin
                    computed_parity_stage1 <= computed_parity_low ^ computed_parity_mid;
                    computed_parity_stage2 <= computed_parity_high ^ ^data_reg[7:6];
                end
                COMPUTE3: begin
                    computed_parity <= (computed_parity_stage1 ^ computed_parity_stage2) ^ parity_type;
                    if (gen_check_n)
                        parity_bit <= (computed_parity_stage1 ^ computed_parity_stage2) ^ parity_type;
                end
                OUTPUT: begin
                    if (!gen_check_n)
                        error <= (computed_parity != parity_bit);
                end
                ERROR_STATE: error <= 1'b1;
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = data_valid ? COMPUTE1 : IDLE;
            COMPUTE1: next = COMPUTE2;
            COMPUTE2: next = COMPUTE3;
            COMPUTE3: next = OUTPUT;
            OUTPUT: next = (!gen_check_n && (computed_parity != parity_bit)) ? 
                          ERROR_STATE : IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule