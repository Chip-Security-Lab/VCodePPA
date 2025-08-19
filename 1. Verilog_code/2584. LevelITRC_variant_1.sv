//SystemVerilog
module LevelITRC #(parameter CHANNELS=4, TIMEOUT=8) (
    input clk, rst,
    input [CHANNELS-1:0] level_irq,
    output reg irq_valid,
    output reg [$clog2(CHANNELS)-1:0] active_channel
);

    // Pipeline stage 1: Input registration and control signal generation
    reg [CHANNELS-1:0] level_irq_reg;
    reg [CHANNELS-1:0] irq_active_reg;
    wire [CHANNELS-1:0] irq_set;
    wire [CHANNELS-1:0] irq_clear;
    
    // Pipeline stage 2: Timeout control
    reg [CHANNELS-1:0] irq_active;
    reg [$clog2(TIMEOUT):0] timeout_counter [0:CHANNELS-1];
    wire [CHANNELS-1:0] timeout_expired;
    wire [CHANNELS-1:0] counter_decrement;
    
    // Pipeline stage 3: Priority encoding
    reg [CHANNELS-1:0] irq_active_prio;
    reg irq_valid_next;
    reg [$clog2(CHANNELS)-1:0] active_channel_next;

    // Stage 1: Input registration and control
    always @(posedge clk) begin
        if (rst) begin
            level_irq_reg <= 0;
            irq_active_reg <= 0;
        end else begin
            level_irq_reg <= level_irq;
            irq_active_reg <= irq_active;
        end
    end

    generate
        for (genvar i = 0; i < CHANNELS; i = i + 1) begin : channel_ctrl
            assign irq_set[i] = level_irq_reg[i] && !irq_active_reg[i];
            assign irq_clear[i] = timeout_expired[i];
        end
    endgenerate

    // Stage 2: Timeout control
    always @(posedge clk) begin
        if (rst) begin
            irq_active <= 0;
            for (integer i = 0; i < CHANNELS; i = i + 1)
                timeout_counter[i] <= 0;
        end else begin
            for (integer i = 0; i < CHANNELS; i = i + 1) begin
                if (irq_set[i]) begin
                    irq_active[i] <= 1;
                    timeout_counter[i] <= TIMEOUT;
                end else if (irq_clear[i]) begin
                    irq_active[i] <= 0;
                end
                
                if (counter_decrement[i]) begin
                    timeout_counter[i] <= timeout_counter[i] - 1;
                end
            end
        end
    end

    generate
        for (genvar i = 0; i < CHANNELS; i = i + 1) begin : timeout_ctrl
            assign timeout_expired[i] = irq_active[i] && (timeout_counter[i] == 0);
            assign counter_decrement[i] = irq_active[i] && (timeout_counter[i] > 0);
        end
    endgenerate

    // Stage 3: Priority encoding
    always @(posedge clk) begin
        if (rst) begin
            irq_active_prio <= 0;
            irq_valid_next <= 0;
            active_channel_next <= 0;
        end else begin
            irq_active_prio <= irq_active;
            irq_valid_next <= |irq_active;
            
            if (irq_active[3]) active_channel_next <= 2'd3;
            else if (irq_active[2]) active_channel_next <= 2'd2;
            else if (irq_active[1]) active_channel_next <= 2'd1;
            else if (irq_active[0]) active_channel_next <= 2'd0;
        end
    end

    // Output registration
    always @(posedge clk) begin
        if (rst) begin
            irq_valid <= 0;
            active_channel <= 0;
        end else begin
            irq_valid <= irq_valid_next;
            active_channel <= active_channel_next;
        end
    end

endmodule