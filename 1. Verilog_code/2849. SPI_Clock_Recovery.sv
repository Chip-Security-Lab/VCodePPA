module SPI_Clock_Recovery #(
    parameter OVERSAMPLE = 8
)(
    input async_clk,
    input sdi,
    output reg recovered_clk,
    output reg [7:0] data_out
);

reg [2:0] sample_window;
reg [3:0] edge_cnt;
reg [7:0] shift_reg;

// Initialize registers
initial begin
    sample_window = 3'b000;
    edge_cnt = 4'h0;
    shift_reg = 8'h00;
    recovered_clk = 1'b0;
    data_out = 8'h00;
end

// Oversampling logic
always @(posedge async_clk) begin
    sample_window <= {sample_window[1:0], sdi};
end

// Edge detection
wire edge_detected = (sample_window[2] ^ sample_window[1]);

// Digital PLL
always @(posedge async_clk) begin
    if(edge_detected) begin
        edge_cnt <= OVERSAMPLE / 2;
        recovered_clk <= 1'b0;
    end else if(edge_cnt == OVERSAMPLE-1) begin
        recovered_clk <= 1'b1;
        edge_cnt <= 0;
    end else begin
        edge_cnt <= edge_cnt + 1;
        recovered_clk <= (edge_cnt < OVERSAMPLE/2);
    end
end

// Data recovery
always @(posedge async_clk) begin
    if(recovered_clk) begin
        shift_reg <= {shift_reg[6:0], sample_window[2]};
    end
end

// Output data register
always @(posedge async_clk) begin
    data_out <= shift_reg;
end
endmodule