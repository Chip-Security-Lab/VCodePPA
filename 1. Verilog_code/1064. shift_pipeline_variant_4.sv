//SystemVerilog
module shift_pipeline #(parameter WIDTH=8, STAGES=3) (
    input                  clk,
    input                  rst_n,
    input                  din_valid,
    input  [WIDTH-1:0]     din,
    output                 dout_valid,
    output [WIDTH-1:0]     dout
);

reg [WIDTH-1:0] stage1_data;
reg [WIDTH-1:0] stage2_data;
reg [WIDTH-1:0] stage3_data;

reg             stage1_valid;
reg             stage2_valid;
reg             stage3_valid;

// Stage 1: din << 1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_data  <= {WIDTH{1'b0}};
        stage1_valid <= 1'b0;
    end else if (rst_n && clk) begin
        stage1_data  <= din << 1;
        stage1_valid <= din_valid;
    end
end

// Stage 2: stage1_data << 1
generate
if (STAGES > 1) begin : gen_stage2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data  <= {WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end else if (rst_n && clk) begin
            stage2_data  <= stage1_data << 1;
            stage2_valid <= stage1_valid;
        end
    end
end else begin : gen_stage2_comb
    always @(*) begin
        stage2_data  = {WIDTH{1'b0}};
        stage2_valid = 1'b0;
    end
end
endgenerate

// Stage 3: stage2_data << 1
generate
if (STAGES > 2) begin : gen_stage3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data  <= {WIDTH{1'b0}};
            stage3_valid <= 1'b0;
        end else if (rst_n && clk) begin
            stage3_data  <= stage2_data << 1;
            stage3_valid <= stage2_valid;
        end
    end
end else begin : gen_stage3_comb
    always @(*) begin
        stage3_data  = {WIDTH{1'b0}};
        stage3_valid = 1'b0;
    end
end
endgenerate

// Output selection and valid signal, flattened if-else structure
assign dout = ((STAGES == 1) && (STAGES != 2) && (STAGES != 3)) ? stage1_data :
              ((STAGES == 2) && (STAGES != 1) && (STAGES != 3)) ? stage2_data :
              ((STAGES == 3) && (STAGES != 1) && (STAGES != 2)) ? stage3_data :
              {WIDTH{1'b0}};

assign dout_valid = ((STAGES == 1) && (STAGES != 2) && (STAGES != 3)) ? stage1_valid :
                    ((STAGES == 2) && (STAGES != 1) && (STAGES != 3)) ? stage2_valid :
                    ((STAGES == 3) && (STAGES != 1) && (STAGES != 2)) ? stage3_valid :
                    1'b0;

endmodule