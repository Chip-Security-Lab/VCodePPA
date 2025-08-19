//SystemVerilog
module MuxSyncReg #(parameter DW=8, AW=3) (
    input wire clk,
    input wire rst_n,
    input wire [AW-1:0] sel,
    input wire [2**AW*DW-1:0] data_in,
    output reg [DW-1:0] data_out
);

    // Stage 1: Register inputs and valid signal
    reg [AW-1:0] sel_stage1;
    reg [2**AW*DW-1:0] data_in_stage1;
    reg valid_stage1;

    // Stage 2: Mux operation and valid signal
    reg [DW-1:0] mux_out_stage2;
    reg valid_stage2;

    // Stage 3: Output register and valid signal
    reg [DW-1:0] data_out_stage3;
    reg valid_stage3;

    integer i;

    // Stage 1: Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1 <= {AW{1'b0}};
            data_in_stage1 <= {(2**AW*DW){1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            sel_stage1 <= sel;
            data_in_stage1 <= data_in;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Mux operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            mux_out_stage2 <= {DW{1'b0}};
            for (i = 0; i < 2**AW; i = i + 1) begin
                if (sel_stage1 == i)
                    mux_out_stage2 <= data_in_stage1[i*DW +: DW];
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            data_out_stage3 <= mux_out_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {DW{1'b0}};
        else if (valid_stage3)
            data_out <= data_out_stage3;
    end

endmodule