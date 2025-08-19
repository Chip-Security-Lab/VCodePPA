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

    localparam IDLE=3'b000, 
               COMPUTE_STAGE1=3'b001, 
               COMPUTE_STAGE2=3'b010,
               COMPUTE_STAGE3=3'b011,
               OUTPUT=3'b100, 
               ERROR_STATE=3'b101;

    reg [2:0] state, next;
    reg [7:0] data_reg;
    reg computed_parity;
    reg [2:0] shift_count;
    reg [7:0] shift_data_stage1, shift_data_stage2;
    reg acc_parity_stage1, acc_parity_stage2;
    
    // Pre-compute constants
    wire [2:0] MAX_SHIFT_STAGE1 = 3'd4;
    wire [2:0] MAX_SHIFT_STAGE3 = 3'd8;
    wire [2:0] NEXT_SHIFT = shift_count + 1'b1;
    
    // Optimize state transitions
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'd0;
            parity_bit <= 1'b0;
            error <= 1'b0;
            computed_parity <= 1'b0;
            shift_count <= 3'd0;
            shift_data_stage1 <= 8'd0;
            shift_data_stage2 <= 8'd0;
            acc_parity_stage1 <= 1'b0;
            acc_parity_stage2 <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    error <= 1'b0;
                    if (data_valid) begin
                        data_reg <= data_in;
                        shift_data_stage1 <= data_in;
                        shift_count <= 3'd0;
                        acc_parity_stage1 <= 1'b0;
                    end
                end
                COMPUTE_STAGE1: begin
                    if (shift_count < MAX_SHIFT_STAGE1) begin
                        // Balance logic by pre-computing shift operation
                        shift_data_stage1 <= {1'b0, shift_data_stage1[7:1]};
                        acc_parity_stage1 <= acc_parity_stage1 ^ shift_data_stage1[0];
                        shift_count <= NEXT_SHIFT;
                    end
                end
                COMPUTE_STAGE2: begin
                    // Simple register transfer with no complex logic
                    shift_data_stage2 <= shift_data_stage1;
                    acc_parity_stage2 <= acc_parity_stage1;
                end
                COMPUTE_STAGE3: begin
                    if (shift_count < MAX_SHIFT_STAGE3) begin
                        // Balance logic by pre-computing shift operation
                        shift_data_stage2 <= {1'b0, shift_data_stage2[7:1]};
                        acc_parity_stage2 <= acc_parity_stage2 ^ shift_data_stage2[0];
                        shift_count <= NEXT_SHIFT;
                    end else begin
                        // Pre-compute parity result
                        computed_parity <= acc_parity_stage2 ^ parity_type;
                        if (gen_check_n)
                            parity_bit <= acc_parity_stage2 ^ parity_type;
                    end
                end
                OUTPUT: begin
                    // Simplified error detection logic
                    if (!gen_check_n)
                        error <= (computed_parity != parity_bit);
                end
                ERROR_STATE: error <= 1'b1;
            endcase
        end
    
    // Optimize next state logic with balanced conditions
    always @(*) begin
        case (state)
            IDLE: next = data_valid ? COMPUTE_STAGE1 : IDLE;
            COMPUTE_STAGE1: next = (shift_count < MAX_SHIFT_STAGE1) ? COMPUTE_STAGE1 : COMPUTE_STAGE2;
            COMPUTE_STAGE2: next = COMPUTE_STAGE3;
            COMPUTE_STAGE3: next = (shift_count < MAX_SHIFT_STAGE3) ? COMPUTE_STAGE3 : OUTPUT;
            OUTPUT: next = (!gen_check_n && (computed_parity != parity_bit)) ? ERROR_STATE : IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase
    end
endmodule