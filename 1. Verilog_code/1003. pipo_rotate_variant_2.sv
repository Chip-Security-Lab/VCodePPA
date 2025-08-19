//SystemVerilog
module pipo_rotate #(
    parameter WIDTH = 16
)(
    input wire                i_clk,
    input wire                i_rst,
    input wire                i_load,
    input wire                i_shift,
    input wire                i_dir,
    input wire [WIDTH-1:0]    i_data,
    output reg [WIDTH-1:0]    o_data
);

    // Stage 1: Input Capture
    reg                     load_stage1, shift_stage1, dir_stage1;
    reg [WIDTH-1:0]         data_stage1;
    reg                     valid_stage1;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            load_stage1   <= 1'b0;
            shift_stage1  <= 1'b0;
            dir_stage1    <= 1'b0;
            data_stage1   <= {WIDTH{1'b0}};
            valid_stage1  <= 1'b0;
        end else begin
            load_stage1   <= i_load;
            shift_stage1  <= i_shift;
            dir_stage1    <= i_dir;
            data_stage1   <= i_data;
            valid_stage1  <= i_load | i_shift;
        end
    end

    // Stage 2: Operation Decode
    reg                     load_stage2, shift_stage2, dir_stage2;
    reg [WIDTH-1:0]         data_stage2;
    reg                     valid_stage2;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            load_stage2   <= 1'b0;
            shift_stage2  <= 1'b0;
            dir_stage2    <= 1'b0;
            data_stage2   <= {WIDTH{1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            load_stage2   <= load_stage1;
            shift_stage2  <= shift_stage1;
            dir_stage2    <= dir_stage1;
            data_stage2   <= data_stage1;
            valid_stage2  <= valid_stage1;
        end
    end

    // Stage 3: Data Register and Shift
    reg [WIDTH-1:0]         pipo_reg_stage3;
    reg                     valid_stage3;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pipo_reg_stage3 <= {WIDTH{1'b0}};
            valid_stage3    <= 1'b0;
        end else begin
            valid_stage3    <= valid_stage2;
            if (load_stage2)
                pipo_reg_stage3 <= data_stage2;
            else if (shift_stage2)
                pipo_reg_stage3 <= dir_stage2 ? {pipo_reg_stage3[WIDTH-2:0], pipo_reg_stage3[WIDTH-1]} 
                                              : {pipo_reg_stage3[0], pipo_reg_stage3[WIDTH-1:1]};
            else
                pipo_reg_stage3 <= pipo_reg_stage3;
        end
    end

    // Output Stage
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            o_data <= {WIDTH{1'b0}};
        else if (valid_stage3)
            o_data <= pipo_reg_stage3;
    end

endmodule