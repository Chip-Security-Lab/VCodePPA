//SystemVerilog
module dram_ctrl_power #(
    parameter LOW_POWER_THRESH = 100
)(
    input clk,
    input activity,
    output reg clk_en
);
    // Pipeline stage 1 registers
    reg [7:0] idle_counter_stage1;
    reg [1:0] state_stage1;
    reg activity_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] idle_counter_stage2;
    reg [1:0] state_stage2;
    reg activity_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] idle_counter_stage3;
    reg [1:0] state_stage3;
    reg clk_en_stage3;
    
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam POWER_DOWN = 2'b10;
    
    // Stage 1: Input sampling and activity detection
    always @(posedge clk) begin
        activity_stage1 <= activity;
        state_stage1 <= state_stage2;
        idle_counter_stage1 <= idle_counter_stage2;
    end
    
    // Stage 2: State transition logic
    always @(posedge clk) begin
        case(state_stage1)
            IDLE: begin
                if(activity_stage1) begin
                    state_stage2 <= ACTIVE;
                    idle_counter_stage2 <= 0;
                end else if(idle_counter_stage1 < LOW_POWER_THRESH) begin
                    idle_counter_stage2 <= idle_counter_stage1 + 1;
                end else begin
                    state_stage2 <= POWER_DOWN;
                end
            end
            ACTIVE: begin
                if(!activity_stage1) begin
                    state_stage2 <= IDLE;
                    idle_counter_stage2 <= 0;
                end else begin
                    state_stage2 <= ACTIVE;
                end
            end
            POWER_DOWN: begin
                if(activity_stage1) begin
                    state_stage2 <= ACTIVE;
                    idle_counter_stage2 <= 0;
                end else begin
                    state_stage2 <= POWER_DOWN;
                end
            end
            default: begin
                state_stage2 <= IDLE;
                idle_counter_stage2 <= 0;
            end
        endcase
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        case(state_stage2)
            IDLE: begin
                if(activity_stage2) begin
                    clk_en_stage3 <= 1;
                end else if(idle_counter_stage2 < LOW_POWER_THRESH) begin
                    clk_en_stage3 <= 1;
                end else begin
                    clk_en_stage3 <= 0;
                end
            end
            ACTIVE: begin
                clk_en_stage3 <= 1;
            end
            POWER_DOWN: begin
                if(activity_stage2) begin
                    clk_en_stage3 <= 1;
                end else begin
                    clk_en_stage3 <= 0;
                end
            end
            default: begin
                clk_en_stage3 <= 1;
            end
        endcase
    end
    
    // Output assignment
    always @(posedge clk) begin
        clk_en <= clk_en_stage3;
    end
endmodule