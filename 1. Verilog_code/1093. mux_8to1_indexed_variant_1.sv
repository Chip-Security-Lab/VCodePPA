//SystemVerilog
module mux_8to1_indexed_pipelined (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire [2:0]  sel_in,
    input  wire        valid_in,
    output wire        data_out,
    output wire        valid_out
);

    // Stage 1: Register input and selector
    reg  [7:0]  data_stage1;
    reg  [2:0]  sel_stage1;
    reg         valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1   <= 8'b0;
            sel_stage1    <= 3'b0;
            valid_stage1  <= 1'b0;
        end else begin
            data_stage1   <= data_in;
            sel_stage1    <= sel_in;
            valid_stage1  <= valid_in;
        end
    end

    // Stage 2: First level multiplexing (8 -> 4)
    reg  [3:0]  mux_stage2;
    reg  [1:0]  sel_stage2;
    reg         valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_stage2    <= 4'b0;
            sel_stage2    <= 2'b0;
            valid_stage2  <= 1'b0;
        end else begin
            mux_stage2[0] <= (sel_stage1[2] == 1'b0) ? data_stage1[0] : data_stage1[4];
            mux_stage2[1] <= (sel_stage1[2] == 1'b0) ? data_stage1[1] : data_stage1[5];
            mux_stage2[2] <= (sel_stage1[2] == 1'b0) ? data_stage1[2] : data_stage1[6];
            mux_stage2[3] <= (sel_stage1[2] == 1'b0) ? data_stage1[3] : data_stage1[7];
            sel_stage2    <= sel_stage1[1:0];
            valid_stage2  <= valid_stage1;
        end
    end

    // Stage 3: Second level multiplexing (4 -> 1)
    reg         mux_stage3;
    reg         valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_stage3   <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            case (sel_stage2)
                2'b00: mux_stage3 <= mux_stage2[0];
                2'b01: mux_stage3 <= mux_stage2[1];
                2'b10: mux_stage3 <= mux_stage2[2];
                2'b11: mux_stage3 <= mux_stage2[3];
                default: mux_stage3 <= 1'b0;
            endcase
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output register
    reg         data_stage4;
    reg         valid_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage4  <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            data_stage4  <= mux_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    assign data_out  = data_stage4;
    assign valid_out = valid_stage4;

endmodule