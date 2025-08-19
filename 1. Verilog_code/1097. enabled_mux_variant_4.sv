//SystemVerilog
module enabled_mux (
    input  wire        clock,           // System clock
    input  wire        enable,          // Enable signal
    input  wire [1:0]  select,          // Input selector
    input  wire [7:0]  in_a,            // Data input A
    input  wire [7:0]  in_b,            // Data input B
    input  wire [7:0]  in_c,            // Data input C
    input  wire [7:0]  in_d,            // Data input D
    output reg  [7:0]  data_out         // Registered output
);

// Stage 1: Input selection (combinational)
wire [7:0] mux_selected_data;
assign mux_selected_data = (select == 2'b00) ? in_a :
                           (select == 2'b01) ? in_b :
                           (select == 2'b10) ? in_c :
                           (select == 2'b11) ? in_d : 8'b0;

// Stage 2: Enable-controlled register (moved register after mux)
reg [7:0] pipeline_data;
always @(posedge clock) begin
    if (enable) begin
        pipeline_data <= mux_selected_data;
    end
end

// Stage 3: Output register
always @(posedge clock) begin
    data_out <= pipeline_data;
end

endmodule