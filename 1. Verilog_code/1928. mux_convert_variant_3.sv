//SystemVerilog
module mux_convert_pipeline #(parameter DW=8, CH=4) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [CH*DW-1:0]       data_in,
    input  wire [$clog2(CH)-1:0]  sel,
    input  wire                   en,
    input  wire                   flush,
    output wire [DW-1:0]          data_out,
    output wire                   data_out_valid
);

    // Stage 1: Latch input and select
    reg  [CH*DW-1:0]              data_in_stage1;
    reg  [$clog2(CH)-1:0]         sel_stage1;
    reg                           en_stage1;
    reg                           valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {CH*DW{1'b0}};
            sel_stage1     <= {($clog2(CH)){1'b0}};
            en_stage1      <= 1'b0;
            valid_stage1   <= 1'b0;
        end else if (flush) begin
            data_in_stage1 <= {CH*DW{1'b0}};
            sel_stage1     <= {($clog2(CH)){1'b0}};
            en_stage1      <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            sel_stage1     <= sel;
            en_stage1      <= en;
            valid_stage1   <= en;
        end
    end

    // Stage 2: Multiplexing logic and latch result
    reg  [DW-1:0]                 mux_data_stage2;
    reg                           en_stage2;
    reg                           valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_data_stage2 <= {DW{1'b0}};
            en_stage2       <= 1'b0;
            valid_stage2    <= 1'b0;
        end else if (flush) begin
            mux_data_stage2 <= {DW{1'b0}};
            en_stage2       <= 1'b0;
            valid_stage2    <= 1'b0;
        end else begin
            mux_data_stage2 <= data_in_stage1[sel_stage1*DW +: DW];
            en_stage2       <= en_stage1;
            valid_stage2    <= valid_stage1;
        end
    end

    // Stage 3: Output register and enable logic
    reg  [DW-1:0]                 data_out_stage3;
    reg                           data_out_valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3       <= {DW{1'b0}};
            data_out_valid_stage3 <= 1'b0;
        end else if (flush) begin
            data_out_stage3       <= {DW{1'b0}};
            data_out_valid_stage3 <= 1'b0;
        end else begin
            data_out_stage3       <= mux_data_stage2;
            data_out_valid_stage3 <= valid_stage2 & en_stage2;
        end
    end

    assign data_out      = data_out_valid_stage3 ? data_out_stage3 : {DW{1'bz}};
    assign data_out_valid = data_out_valid_stage3;

endmodule