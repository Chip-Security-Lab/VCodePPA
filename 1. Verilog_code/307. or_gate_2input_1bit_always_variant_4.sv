//SystemVerilog
// SystemVerilog
// Top-level module with Valid-Ready handshake interface and improved pipeline structure
module or_gate_2input_1bit_always (
    input wire clk,
    input wire rst_n,
    
    // Input interface
    input wire a,
    input wire b,
    input wire valid_in,
    output wire ready_in,
    
    // Output interface
    output reg y,
    output reg valid_out,
    input wire ready_out
);
    // Pipeline stage registers for clear data flow
    reg a_stage1, b_stage1;       // Input capture stage
    reg valid_stage1;             // Validity tracking through pipeline
    reg result_stage2;            // Computation result stage
    reg valid_stage2;             // Validity tracking for output stage
    
    // FSM state definition
    localparam IDLE      = 2'b00,
               COMPUTE   = 2'b01,
               RESULT    = 2'b10;
    
    reg [1:0] current_state, next_state;
    
    // Handshake control with improved timing
    assign ready_in = (current_state == IDLE) || 
                     ((current_state == RESULT) && valid_out && ready_out);
    
    // FSM State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // FSM Next state logic
    always @(*) begin
        next_state = current_state; // Default: stay in current state
        
        case (current_state)
            IDLE: begin
                if (valid_in && ready_in) 
                    next_state = COMPUTE;
            end
            COMPUTE: begin
                next_state = RESULT;
            end
            RESULT: begin
                if (valid_out && ready_out)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Stage 1: Input capture and registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (current_state == IDLE && valid_in && ready_in) begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= 1'b1;
        end else if (current_state == COMPUTE) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Computation and result registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (current_state == COMPUTE) begin
            result_stage2 <= a_stage1 | b_stage1; // OR operation
            valid_stage2 <= valid_stage1;
        end else if (current_state == RESULT && valid_out && ready_out) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Output stage: Transfer results to output ports
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
            valid_out <= 1'b0;
        end else if (current_state == COMPUTE) begin
            y <= result_stage2;
            valid_out <= valid_stage2;
        end else if (current_state == RESULT && valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule

// Dadda multiplier module with improved pipeline structure and clear data paths
module dadda_multiplier_8bit (
    input wire clk,
    input wire rst_n,
    
    // Input interface
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid_in,
    output wire ready_in,
    
    // Output interface
    output reg [15:0] product,
    output reg valid_out,
    input wire ready_out
);
    // Pipeline stage definitions for clear data flow
    localparam STAGE_PP_GEN     = 3'b001; // Partial product generation
    localparam STAGE_REDUCTION1 = 3'b010; // First reduction stage
    localparam STAGE_REDUCTION2 = 3'b011; // Second reduction stage 
    localparam STAGE_FINAL_ADD  = 3'b100; // Final addition stage
    
    // FSM state definition
    localparam IDLE      = 2'b00,
               PROCESS   = 2'b01,
               OUTPUT    = 2'b10;
               
    reg [1:0] current_state, next_state;
    reg [2:0] pipeline_stage;
    
    // Input registers
    reg [7:0] a_reg, b_reg;
    reg input_valid;
    
    // Partial product arrays with clear structure
    reg [63:0] pp_stage1;      // Partial products storage
    reg valid_stage1;          // Stage 1 validity flag
    
    // Reduction stage registers
    reg [15:0] sum_stage2;     // First reduction stage results
    reg [15:0] carry_stage2;   // First reduction carries
    reg valid_stage2;          // Stage 2 validity flag
    
    reg [15:0] sum_stage3;     // Second reduction stage results
    reg [15:0] carry_stage3;   // Second reduction carries
    reg valid_stage3;          // Stage 3 validity flag
    
    reg [15:0] result_stage4;  // Final addition result
    reg valid_stage4;          // Stage 4 validity flag
    
    // Handshake control for consistent timing
    assign ready_in = (current_state == IDLE) || 
                     ((current_state == OUTPUT) && valid_out && ready_out);
    
    // FSM state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            pipeline_stage <= 3'b000;
        end else begin
            current_state <= next_state;
            
            // Pipeline stage control
            if (current_state == PROCESS) begin
                if (pipeline_stage == STAGE_FINAL_ADD)
                    pipeline_stage <= 3'b000;
                else
                    pipeline_stage <= pipeline_stage + 3'b001;
            end else if (current_state == IDLE && valid_in && ready_in) begin
                pipeline_stage <= STAGE_PP_GEN;
            end
        end
    end
    
    // FSM next state logic
    always @(*) begin
        next_state = current_state; // Default: stay in current state
        
        case (current_state)
            IDLE: begin
                if (valid_in && ready_in)
                    next_state = PROCESS;
            end
            PROCESS: begin
                if (pipeline_stage == STAGE_FINAL_ADD)
                    next_state = OUTPUT;
            end
            OUTPUT: begin
                if (valid_out && ready_out)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Stage 1: Input capture and partial products generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            input_valid <= 1'b0;
            pp_stage1 <= 64'b0;
            valid_stage1 <= 1'b0;
        end else begin
            // Input capture
            if (current_state == IDLE && valid_in && ready_in) begin
                a_reg <= a;
                b_reg <= b;
                input_valid <= 1'b1;
            end
            
            // Partial products generation
            if (current_state == PROCESS && pipeline_stage == STAGE_PP_GEN) begin
                // Generate all partial products in parallel
                for (integer i = 0; i < 8; i = i + 1) begin
                    for (integer j = 0; j < 8; j = j + 1) begin
                        pp_stage1[i*8+j] <= a_reg[j] & b_reg[i];
                    end
                end
                valid_stage1 <= input_valid;
                input_valid <= 1'b0;
            end
        end
    end
    
    // Stage 2: First reduction stage - reduce partial products
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2 <= 16'b0;
            carry_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end else if (current_state == PROCESS && pipeline_stage == STAGE_REDUCTION1) begin
            // First level dadda reduction would happen here
            // Simplified for demonstration - would use compressors in actual implementation
            sum_stage2[0] <= pp_stage1[0];
            sum_stage2[1] <= pp_stage1[1] ^ pp_stage1[8];
            carry_stage2[1] <= pp_stage1[1] & pp_stage1[8];
            // ... additional reduction logic for all bit positions
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Second reduction stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage3 <= 16'b0;
            carry_stage3 <= 16'b0;
            valid_stage3 <= 1'b0;
        end else if (current_state == PROCESS && pipeline_stage == STAGE_REDUCTION2) begin
            // Second level dadda reduction
            // Simplified for demonstration
            sum_stage3[0] <= sum_stage2[0];
            sum_stage3[1] <= sum_stage2[1] ^ carry_stage2[0];
            carry_stage3[1] <= sum_stage2[1] & carry_stage2[0];
            // ... additional reduction logic for all bit positions
            
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Final addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage4 <= 16'b0;
            valid_stage4 <= 1'b0;
        end else if (current_state == PROCESS && pipeline_stage == STAGE_FINAL_ADD) begin
            // Final addition of sum and carry vectors
            result_stage4 <= sum_stage3 + {carry_stage3[14:0], 1'b0};
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
            valid_out <= 1'b0;
        end else if (current_state == OUTPUT && !valid_out) begin
            product <= result_stage4;
            valid_out <= valid_stage4;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule