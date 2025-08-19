//SystemVerilog
module des_cbc_async (
    input wire clk,         // Clock signal
    input wire rst_n,       // Active low reset
    
    // Data input interface (Valid-Ready)
    input wire [63:0] din,  // Data input
    input wire [63:0] iv,   // Initialization vector
    input wire [55:0] key,  // Encryption key
    input wire valid_in,    // Input data valid
    output reg ready_in,    // Ready to accept input
    
    // Data output interface (Valid-Ready)
    output reg [63:0] dout, // Data output
    output reg valid_out,   // Output data valid
    input wire ready_out    // Downstream ready
);

    // Internal registers and wires
    reg [63:0] xor_stage1_reg;
    reg [63:0] swap_stage2_reg;
    reg [31:0] feistel_stage3_reg;
    reg [63:0] shuffle_stage4_reg;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg [63:0] iv_reg;
    
    // State machine states
    localparam IDLE = 3'b000;
    localparam STAGE1 = 3'b001;  // XOR Stage
    localparam STAGE2 = 3'b010;  // Swap Stage
    localparam STAGE3 = 3'b011;  // Feistel Stage
    localparam STAGE4 = 3'b100;  // Final Shuffle Stage
    localparam WAIT_OUTPUT = 3'b101;
    reg [2:0] state, next_state;
    
    // Pipeline control signals
    reg pipeline_stall;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
            ready_in <= 1'b1;
            valid_out <= 1'b0;
            dout <= 64'h0;
            xor_stage1_reg <= 64'h0;
            swap_stage2_reg <= 64'h0;
            feistel_stage3_reg <= 32'h0;
            shuffle_stage4_reg <= 64'h0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            iv_reg <= 64'h0;
        end else begin
            state <= next_state;
            
            // Pipeline stall condition
            pipeline_stall = valid_out && !ready_out;
            
            if (!pipeline_stall) begin
                // Stage 4 (Final Shuffle)
                if (valid_stage3) begin
                    shuffle_stage4_reg <= {swap_stage2_reg[31:0], swap_stage2_reg[63:32] ^ feistel_stage3_reg};
                    valid_stage4 <= valid_stage3;
                end else begin
                    valid_stage4 <= 1'b0;
                end
                
                // Stage 3 (Feistel Network)
                if (valid_stage2) begin
                    feistel_stage3_reg <= key[31:0];  // Simplified Feistel function
                    valid_stage3 <= valid_stage2;
                end else begin
                    valid_stage3 <= 1'b0;
                end
                
                // Stage 2 (Swap Operation)
                if (valid_stage1) begin
                    swap_stage2_reg <= {xor_stage1_reg[31:0], xor_stage1_reg[63:32]};
                    valid_stage2 <= valid_stage1;
                end else begin
                    valid_stage2 <= 1'b0;
                end
                
                // Stage 1 (Input XOR)
                case (state)
                    IDLE: begin
                        if (valid_in && ready_in) begin
                            xor_stage1_reg <= din ^ iv;
                            iv_reg <= din;  // Save for next block in CBC mode
                            valid_stage1 <= 1'b1;
                            ready_in <= 1'b0;
                        end else begin
                            valid_stage1 <= 1'b0;
                        end
                    end
                    
                    default: begin
                        valid_stage1 <= 1'b0;
                    end
                endcase
                
                // Output stage
                if (valid_stage4 && state == STAGE4) begin
                    dout <= {shuffle_stage4_reg[15:0], shuffle_stage4_reg[63:16]};
                    valid_out <= 1'b1;
                end else if (state == WAIT_OUTPUT && ready_out) begin
                    valid_out <= 1'b0;
                    ready_in <= 1'b1;
                end
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (valid_in && ready_in)
                    next_state = STAGE1;
            end
            
            STAGE1: begin
                if (!pipeline_stall)
                    next_state = STAGE2;
            end
            
            STAGE2: begin
                if (!pipeline_stall)
                    next_state = STAGE3;
            end
            
            STAGE3: begin
                if (!pipeline_stall)
                    next_state = STAGE4;
            end
            
            STAGE4: begin
                if (!pipeline_stall)
                    next_state = WAIT_OUTPUT;
            end
            
            WAIT_OUTPUT: begin
                if (ready_out && valid_out)
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
endmodule