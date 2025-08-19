//SystemVerilog
module shift_dynamic_cfg #(parameter WIDTH = 8) (
    input clk,
    input rst_n,
    input valid_in,
    input [1:0] cfg_mode_in, // 00-hold, 01-left, 10-right, 11-load
    input [WIDTH-1:0] cfg_data_in,
    output reg valid_out,
    output reg [WIDTH-1:0] dout
);

    // Stage 1: Latch input and previous output, perform shift/load in single stage
    reg [1:0] cfg_mode_stage1;
    reg [WIDTH-1:0] cfg_data_stage1;
    reg [WIDTH-1:0] data_stage1;
    reg valid_stage1;

    // Stage 2: Output register
    reg [WIDTH-1:0] dout_stage2;
    reg valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_mode_stage1 <= 2'b00;
            cfg_data_stage1 <= {WIDTH{1'b0}};
            data_stage1     <= {WIDTH{1'b0}};
            valid_stage1    <= 1'b0;
        end else begin
            cfg_mode_stage1 <= cfg_mode_in;
            cfg_data_stage1 <= cfg_data_in;
            data_stage1     <= dout;
            valid_stage1    <= valid_in;
        end
    end

    // Stage 2: Perform shift/load operation and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2  <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            case (cfg_mode_stage1)
                2'b01: dout_stage2 <= {data_stage1[WIDTH-2:0], 1'b0}; // left shift
                2'b10: dout_stage2 <= {1'b0, data_stage1[WIDTH-1:1]}; // right shift
                2'b11: dout_stage2 <= cfg_data_stage1;                // load
                default: dout_stage2 <= data_stage1;                  // hold
            endcase
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout      <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            dout      <= dout_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule