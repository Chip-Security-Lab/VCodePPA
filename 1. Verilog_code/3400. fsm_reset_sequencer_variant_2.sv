//SystemVerilog
module boot_sequence_reset (
    input  wire       clk,
    input  wire       power_good,
    output reg  [3:0] rst_seq,
    output reg        boot_complete
);
    // Boot sequence stage definitions
    localparam BOOT_INIT     = 3'd0;
    localparam BOOT_STAGE1   = 3'd1;
    localparam BOOT_STAGE2   = 3'd2;
    localparam BOOT_STAGE3   = 3'd3;
    localparam BOOT_COMPLETE = 3'd4;
    
    // Pipeline registers for boot sequence control
    reg [2:0] boot_stage_r;
    reg [2:0] boot_stage_next;
    
    // Reset sequence pipeline registers
    reg [3:0] rst_seq_next;
    
    // Boot complete status pipeline
    reg boot_complete_next;
    
    // Boot stage controller - determines next boot stage
    always @(*) begin
        if (boot_stage_r < BOOT_COMPLETE)
            boot_stage_next = boot_stage_r + 1'b1;
        else
            boot_stage_next = boot_stage_r;
    end
    
    // Reset sequence generation logic
    always @(*) begin
        if (!power_good) begin
            rst_seq_next = 4'b1111;
        end else if (boot_stage_r < BOOT_COMPLETE) begin
            rst_seq_next = rst_seq >> 1;
        end else begin
            rst_seq_next = rst_seq;
        end
    end
    
    // Boot completion detection
    always @(*) begin
        boot_complete_next = (boot_stage_r == BOOT_STAGE3);
    end
    
    // Sequential logic with power_good reset
    always @(posedge clk or negedge power_good) begin
        if (!power_good) begin
            // Reset all pipeline stages
            boot_stage_r   <= BOOT_INIT;
            rst_seq        <= 4'b1111;
            boot_complete  <= 1'b0;
        end else begin
            // Update pipeline registers
            boot_stage_r   <= boot_stage_next;
            rst_seq        <= rst_seq_next;
            boot_complete  <= boot_complete_next;
        end
    end
    
endmodule