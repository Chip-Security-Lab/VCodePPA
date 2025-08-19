//SystemVerilog
module int_ctrl_trig_type #(parameter WIDTH=4)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] int_src,
    input wire [WIDTH-1:0] trig_type,  // 0=level 1=edge
    input wire valid_in,
    output wire valid_out,
    output wire [WIDTH-1:0] int_out
);

// Stage 1: Input synchronization and edge detection
reg [WIDTH-1:0] sync_reg_stage1, prev_reg_stage1;
reg valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sync_reg_stage1 <= {WIDTH{1'b0}};
        prev_reg_stage1 <= {WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        prev_reg_stage1 <= sync_reg_stage1;
        sync_reg_stage1 <= int_src;
        valid_stage1 <= valid_in;
    end
end

// Stage 1 outputs
wire [WIDTH-1:0] edge_detected_stage1;
wire [WIDTH-1:0] trig_type_stage1;

generate
    genvar i;
    for (i = 0; i < WIDTH; i = i + 1) begin : edge_detect_logic
        assign edge_detected_stage1[i] = sync_reg_stage1[i] & ~prev_reg_stage1[i];
    end
endgenerate

// Pipeline registers between stage 1 and 2
reg [WIDTH-1:0] edge_detected_stage2;
reg [WIDTH-1:0] sync_reg_stage2;
reg [WIDTH-1:0] trig_type_stage2;
reg valid_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_detected_stage2 <= {WIDTH{1'b0}};
        sync_reg_stage2 <= {WIDTH{1'b0}};
        trig_type_stage2 <= {WIDTH{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        edge_detected_stage2 <= edge_detected_stage1;
        sync_reg_stage2 <= sync_reg_stage1;
        trig_type_stage2 <= trig_type;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 2: Final output selection based on trigger type
reg [WIDTH-1:0] int_out_reg;
reg valid_out_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        int_out_reg <= {WIDTH{1'b0}};
        valid_out_reg <= 1'b0;
    end else begin
        valid_out_reg <= valid_stage2;
        for (int j = 0; j < WIDTH; j = j + 1) begin
            int_out_reg[j] <= trig_type_stage2[j] ? edge_detected_stage2[j] : sync_reg_stage2[j];
        end
    end
end

// Output assignments
assign int_out = int_out_reg;
assign valid_out = valid_out_reg;

endmodule