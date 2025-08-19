//SystemVerilog
module triple_flop_sync #(parameter DW = 16) (
    input wire dest_clock,
    input wire reset,
    input wire enable,
    input wire [DW-1:0] async_data,
    output reg [DW-1:0] sync_data
);
    reg [DW-1:0] stage1_reg, stage2_reg, stage3_reg;

    typedef enum reg [1:0] {RESET=2'b01, ENABLE=2'b10, IDLE=2'b00} sync_state_t;
    reg [1:0] sync_state_reg;

    // Move state register ahead of data path
    always @(posedge dest_clock or posedge reset) begin
        if (reset)
            sync_state_reg <= RESET;
        else if (enable)
            sync_state_reg <= ENABLE;
        else
            sync_state_reg <= IDLE;
    end

    // Move all registers before output, so output is pure register
    always @(posedge dest_clock) begin
        case (sync_state_reg)
            RESET: begin
                stage1_reg   <= {DW{1'b0}};
                stage2_reg   <= {DW{1'b0}};
                stage3_reg   <= {DW{1'b0}};
            end
            ENABLE: begin
                stage1_reg   <= async_data;
                stage2_reg   <= stage1_reg;
                stage3_reg   <= stage2_reg;
            end
            default: begin
                stage1_reg   <= stage1_reg;
                stage2_reg   <= stage2_reg;
                stage3_reg   <= stage3_reg;
            end
        endcase
    end

    // Output is now a direct register tap, no additional register at output
    always @(posedge dest_clock) begin
        sync_data <= stage3_reg;
    end

endmodule