//SystemVerilog
module SPI_Clock_Recovery #(
    parameter OVERSAMPLE = 8
)(
    input  wire        async_clk,
    input  wire        sdi,
    output reg         recovered_clk,
    output reg [7:0]   data_out
);

reg [2:0] sample_window_reg;
reg [2:0] sample_window_buf;
reg [3:0] edge_cnt_reg;
reg [3:0] edge_cnt_buf;
reg [7:0] shift_reg_reg;
reg [7:0] shift_reg_buf;

// Initialize registers
initial begin
    sample_window_reg = 3'b000;
    sample_window_buf = 3'b000;
    edge_cnt_reg      = 4'h0;
    edge_cnt_buf      = 4'h0;
    shift_reg_reg     = 8'h00;
    shift_reg_buf     = 8'h00;
    recovered_clk     = 1'b0;
    data_out          = 8'h00;
end

// Oversampling logic with buffering
always @(posedge async_clk) begin
    sample_window_reg <= {sample_window_reg[1:0], sdi};
    sample_window_buf <= sample_window_reg;
end

// Edge detection
wire edge_detected = (sample_window_buf[2] ^ sample_window_buf[1]);

// Digital PLL with edge_cnt buffering
always @(posedge async_clk) begin
    if(edge_detected) begin
        edge_cnt_reg <= OVERSAMPLE / 2;
        edge_cnt_buf <= OVERSAMPLE / 2;
        recovered_clk <= 1'b0;
    end else if(edge_cnt_reg == OVERSAMPLE-1) begin
        recovered_clk <= 1'b1;
        edge_cnt_reg <= 4'h0;
        edge_cnt_buf <= 4'h0;
    end else begin
        edge_cnt_reg <= edge_cnt_reg + 1;
        edge_cnt_buf <= edge_cnt_reg + 1;
        recovered_clk <= (edge_cnt_reg < (OVERSAMPLE/2));
    end
end

// Data recovery with shift_reg buffering
always @(posedge async_clk) begin
    if(recovered_clk) begin
        shift_reg_reg <= {shift_reg_reg[6:0], sample_window_buf[2]};
        shift_reg_buf <= {shift_reg_reg[6:0], sample_window_buf[2]};
    end else begin
        shift_reg_buf <= shift_reg_reg;
    end
end

// Output data register using buffered shift_reg
always @(posedge async_clk) begin
    data_out <= shift_reg_buf;
end

endmodule