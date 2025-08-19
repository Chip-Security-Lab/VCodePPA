//SystemVerilog
module MuxShiftRegister #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  sel,
    input  wire [1:0]            serial_in,
    input  wire                  valid_in,
    output wire                  ready_out,
    output reg  [WIDTH-1:0]      data_out,
    output wire                  valid_out
);

// Stage 1: Register input signals
reg        sel_stage1;
reg [1:0]  serial_in_stage1;
reg        valid_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sel_stage1       <= 1'b0;
    end else begin
        sel_stage1       <= sel;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        serial_in_stage1 <= 2'b00;
    end else begin
        serial_in_stage1 <= serial_in;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1     <= 1'b0;
    end else begin
        valid_stage1     <= valid_in;
    end
end

// Stage 2: Mux selection and shift operation
reg [WIDTH-2:0] shift_data_stage2;
reg [WIDTH-1:0] data_out_stage2;
reg             valid_stage2;

// Shift data generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_data_stage2 <= { (WIDTH-1){1'b0} };
    end else if (valid_stage1) begin
        shift_data_stage2 <= data_out[WIDTH-2:0];
    end
end

// Mux and shift logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out_stage2 <= { WIDTH{1'b0} };
    end else if (valid_stage1) begin
        case (sel_stage1)
            1'b0: data_out_stage2 <= {data_out[WIDTH-2:0], serial_in_stage1[0]};
            1'b1: data_out_stage2 <= {data_out[WIDTH-2:0], serial_in_stage1[1]};
            default: data_out_stage2 <= {WIDTH{1'b0}};
        endcase
    end
end

// Valid pipeline register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage2 <= 1'b0;
    end else begin
        valid_stage2 <= valid_stage1;
    end
end

// Output stage: Register output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= { WIDTH{1'b0} };
    end else if (valid_stage2) begin
        data_out <= data_out_stage2;
    end
end

assign valid_out  = valid_stage2;
assign ready_out  = 1'b1;

endmodule