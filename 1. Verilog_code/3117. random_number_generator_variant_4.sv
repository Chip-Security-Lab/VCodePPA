//SystemVerilog
module random_number_generator(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_seed,
    output wire [15:0] random_value
);
    wire [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
    wire [15:0] lfsr_reg_stage1, lfsr_reg_stage2;
    wire feedback_stage1, feedback_stage2;
    wire load_lfsr_stage1, load_lfsr_stage2;
    wire generate_random_stage1, generate_random_stage2;
    
    state_controller state_ctrl_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load_seed(load_seed),
        .state_stage1(state_stage1),
        .state_stage2(state_stage2),
        .next_state_stage1(next_state_stage1),
        .next_state_stage2(next_state_stage2),
        .load_lfsr_stage1(load_lfsr_stage1),
        .load_lfsr_stage2(load_lfsr_stage2),
        .generate_random_stage1(generate_random_stage1),
        .generate_random_stage2(generate_random_stage2)
    );
    
    lfsr_core lfsr_inst (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .seed(seed),
        .load_lfsr_stage1(load_lfsr_stage1),
        .load_lfsr_stage2(load_lfsr_stage2),
        .generate_random_stage1(generate_random_stage1),
        .generate_random_stage2(generate_random_stage2),
        .state_stage1(state_stage1),
        .state_stage2(state_stage2),
        .lfsr_reg_stage1(lfsr_reg_stage1),
        .lfsr_reg_stage2(lfsr_reg_stage2),
        .feedback_stage1(feedback_stage1),
        .feedback_stage2(feedback_stage2),
        .random_value(random_value)
    );
endmodule

module state_controller(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire load_seed,
    output reg [1:0] state_stage1,
    output reg [1:0] state_stage2,
    output reg [1:0] next_state_stage1,
    output reg [1:0] next_state_stage2,
    output wire load_lfsr_stage1,
    output wire load_lfsr_stage2,
    output wire generate_random_stage1,
    output wire generate_random_stage2
);
    localparam [1:0] IDLE = 2'b00, 
                     LOAD = 2'b01, 
                     GENERATE = 2'b10;
    
    reg [1:0] state_stage1_next, state_stage2_next;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_stage1 <= IDLE;
            state_stage2 <= IDLE;
        end else begin
            state_stage1 <= state_stage1_next;
            state_stage2 <= state_stage2_next;
        end
    end
    
    always @(*) begin
        case (state_stage1)
            IDLE: begin
                if (load_seed)
                    state_stage1_next = LOAD;
                else if (enable)
                    state_stage1_next = GENERATE;
                else
                    state_stage1_next = IDLE;
            end
            LOAD: begin
                state_stage1_next = GENERATE;
            end
            GENERATE: begin
                if (!enable)
                    state_stage1_next = IDLE;
                else if (load_seed)
                    state_stage1_next = LOAD;
                else
                    state_stage1_next = GENERATE;
            end
            default: state_stage1_next = IDLE;
        endcase
    end
    
    always @(*) begin
        case (state_stage2)
            IDLE: begin
                if (load_seed)
                    state_stage2_next = LOAD;
                else if (enable)
                    state_stage2_next = GENERATE;
                else
                    state_stage2_next = IDLE;
            end
            LOAD: begin
                state_stage2_next = GENERATE;
            end
            GENERATE: begin
                if (!enable)
                    state_stage2_next = IDLE;
                else if (load_seed)
                    state_stage2_next = LOAD;
                else
                    state_stage2_next = GENERATE;
            end
            default: state_stage2_next = IDLE;
        endcase
    end
    
    assign load_lfsr_stage1 = (state_stage1 == LOAD);
    assign load_lfsr_stage2 = (state_stage2 == LOAD);
    assign generate_random_stage1 = (state_stage1 == GENERATE) && enable;
    assign generate_random_stage2 = (state_stage2 == GENERATE) && enable;
endmodule

module lfsr_core(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [7:0] seed,
    input wire load_lfsr_stage1,
    input wire load_lfsr_stage2,
    input wire generate_random_stage1,
    input wire generate_random_stage2,
    input wire [1:0] state_stage1,
    input wire [1:0] state_stage2,
    output reg [15:0] lfsr_reg_stage1,
    output reg [15:0] lfsr_reg_stage2,
    output wire feedback_stage1,
    output wire feedback_stage2,
    output reg [15:0] random_value
);
    reg [15:0] lfsr_reg_stage1_next, lfsr_reg_stage2_next;
    reg [15:0] random_value_next;
    
    assign feedback_stage1 = lfsr_reg_stage1[15] ^ lfsr_reg_stage1[14] ^ lfsr_reg_stage1[12] ^ lfsr_reg_stage1[3];
    assign feedback_stage2 = lfsr_reg_stage2[15] ^ lfsr_reg_stage2[14] ^ lfsr_reg_stage2[12] ^ lfsr_reg_stage2[3];
    
    always @(*) begin
        if (load_lfsr_stage1) begin
            lfsr_reg_stage1_next = {seed, 8'h01};
        end else if (generate_random_stage1) begin
            lfsr_reg_stage1_next = {lfsr_reg_stage1[14:0], feedback_stage1};
        end else begin
            lfsr_reg_stage1_next = lfsr_reg_stage1;
        end
        
        if (load_lfsr_stage2) begin
            lfsr_reg_stage2_next = {seed, 8'h01};
        end else if (generate_random_stage2) begin
            lfsr_reg_stage2_next = {lfsr_reg_stage2[14:0], feedback_stage2};
            random_value_next = lfsr_reg_stage2;
        end else begin
            lfsr_reg_stage2_next = lfsr_reg_stage2;
            random_value_next = random_value;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr_reg_stage1 <= 16'h1234;
            lfsr_reg_stage2 <= 16'h1234;
            random_value <= 16'h0000;
        end else begin
            lfsr_reg_stage1 <= lfsr_reg_stage1_next;
            lfsr_reg_stage2 <= lfsr_reg_stage2_next;
            random_value <= random_value_next;
        end
    end
endmodule