//SystemVerilog
module sync_1to8_demux (
    input wire clock,                        // System clock
    input wire reset,                        // Asynchronous active-high reset
    input wire data,                         // Input data
    input wire [2:0] address,                // 3-bit address
    output reg [7:0] outputs                 // 8 registered outputs
);

    // Stage 1 registers: input latching
    reg data_stage1;
    reg [2:0] address_stage1;

    // Stage 2 registers: decode and mask generation
    reg [7:0] mask_stage2;
    reg data_stage2;

    // Stage 3 registers: outputs
    reg [7:0] outputs_stage3;

    // Stage 1: Latch inputs
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            data_stage1    <= 1'b0;
            address_stage1 <= 3'b0;
        end else begin
            data_stage1    <= data;
            address_stage1 <= address;
        end
    end

    // Stage 2: Decode address to one-hot mask using barrel shifter and latch data
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mask_stage2  <= 8'b0;
            data_stage2  <= 1'b0;
        end else begin
            // Barrel shifter for 8'b1 << address_stage1
            case (address_stage1)
                3'd0: mask_stage2 <= 8'b0000_0001;
                3'd1: mask_stage2 <= 8'b0000_0010;
                3'd2: mask_stage2 <= 8'b0000_0100;
                3'd3: mask_stage2 <= 8'b0000_1000;
                3'd4: mask_stage2 <= 8'b0001_0000;
                3'd5: mask_stage2 <= 8'b0010_0000;
                3'd6: mask_stage2 <= 8'b0100_0000;
                3'd7: mask_stage2 <= 8'b1000_0000;
                default: mask_stage2 <= 8'b0000_0001;
            endcase
            data_stage2  <= data_stage1;
        end
    end

    // Stage 3: Generate output vector
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            outputs_stage3 <= 8'b0;
        end else begin
            outputs_stage3 <= mask_stage2 & {8{data_stage2}};
        end
    end

    // Outputs register
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            outputs <= 8'b0;
        end else begin
            outputs <= outputs_stage3;
        end
    end

endmodule