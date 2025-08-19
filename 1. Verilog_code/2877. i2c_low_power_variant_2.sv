//SystemVerilog
module i2c_low_power #(
    parameter AUTO_CLKGATE = 1  // Automatic clock gating
)(
    input clk_main,
    input rst_n,
    input enable,
    inout sda,
    inout scl,
    output reg clk_gated
);
    // State definitions with finer granularity
    parameter IDLE = 3'b000;
    parameter ACTIVE_PREP = 3'b001;
    parameter ACTIVE_EXEC = 3'b010;
    parameter TRANSFER_ADDR = 3'b011;
    parameter TRANSFER_DATA = 3'b100;
    parameter TRANSFER_ACK = 3'b101;
    parameter COOLDOWN = 3'b110;
    
    // Retimed pipeline structure
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [3:0] fifo_count_stage1, fifo_count_stage2, fifo_count_stage3;
    
    // Clock enable signals moved after combinational logic
    wire clk_enable_stage1, clk_enable_stage2, clk_enable_stage3;
    reg clk_enable_stage1_reg, clk_enable_stage2_reg, clk_enable_stage3_reg;
    
    // Combinational logic for clock enable signals moved before registers
    assign clk_enable_stage1 = (state_stage1 != IDLE) || (|fifo_count_stage1);
    assign clk_enable_stage2 = (state_stage1 != IDLE && state_stage1 != COOLDOWN) || 
                              (fifo_count_stage1 > 4'h1);
    assign clk_enable_stage3 = (state_stage2 == ACTIVE_EXEC || 
                               state_stage2 == TRANSFER_ADDR || 
                               state_stage2 == TRANSFER_DATA || 
                               state_stage2 == TRANSFER_ACK) || 
                               (fifo_count_stage2 > 4'h2);
    
    // Retimed gated clock generation - moved logic before registers
    wire gated_clk_stage1, gated_clk_stage2, gated_clk_stage3;
    assign gated_clk_stage1 = clk_main & clk_enable_stage1_reg;
    assign gated_clk_stage2 = gated_clk_stage1 & clk_enable_stage2_reg;
    assign gated_clk_stage3 = gated_clk_stage2 & clk_enable_stage3_reg;

    // State transition combinational logic
    reg [2:0] next_state_stage1;
    reg [3:0] next_fifo_count_stage1;
    
    always @(*) begin
        // Default values
        next_state_stage1 = state_stage1;
        next_fifo_count_stage1 = fifo_count_stage1;
        
        // State transition logic
        case (state_stage1)
            IDLE: if (enable) next_state_stage1 = ACTIVE_PREP;
            ACTIVE_PREP: next_state_stage1 = ACTIVE_EXEC;
            ACTIVE_EXEC: if (!enable) next_state_stage1 = COOLDOWN;
                       else next_state_stage1 = TRANSFER_ADDR;
            TRANSFER_ADDR: next_state_stage1 = TRANSFER_DATA;
            TRANSFER_DATA: next_state_stage1 = TRANSFER_ACK;
            TRANSFER_ACK: if (enable) next_state_stage1 = TRANSFER_ADDR;
                        else next_state_stage1 = COOLDOWN;
            COOLDOWN: next_state_stage1 = IDLE;
            default: next_state_stage1 = IDLE;
        endcase
        
        // FIFO count logic first stage
        if (enable && fifo_count_stage1 < 4'hF)
            next_fifo_count_stage1 = fifo_count_stage1 + 1;
        else if (!enable && fifo_count_stage1 > 0)
            next_fifo_count_stage1 = fifo_count_stage1 - 1;
    end
    
    // Pipeline stage 1: State transition and basic logic
    always @(posedge clk_main or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            fifo_count_stage1 <= 4'h0;
            clk_enable_stage1_reg <= 0;
        end else begin
            state_stage1 <= next_state_stage1;
            fifo_count_stage1 <= next_fifo_count_stage1;
            clk_enable_stage1_reg <= clk_enable_stage1;
        end
    end

    // Pipeline stage 2: Intermediate processing
    always @(posedge clk_main or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            fifo_count_stage2 <= 4'h0;
            clk_enable_stage2_reg <= 0;
        end else begin
            state_stage2 <= state_stage1;
            fifo_count_stage2 <= fifo_count_stage1;
            clk_enable_stage2_reg <= clk_enable_stage2;
        end
    end

    // Pipeline stage 3: Final output stage
    always @(posedge clk_main or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            fifo_count_stage3 <= 4'h0;
            clk_enable_stage3_reg <= 0;
            clk_gated <= 0;
        end else begin
            state_stage3 <= state_stage2;
            fifo_count_stage3 <= fifo_count_stage2;
            clk_enable_stage3_reg <= clk_enable_stage3;
            clk_gated <= gated_clk_stage3;
        end
    end

    // Using clock gating unit (synthesis directive)
    // synopsys translate_off
    initial $display("Using retimed multi-stage pipelined clock gating technique");
    // synopsys translate_on
endmodule