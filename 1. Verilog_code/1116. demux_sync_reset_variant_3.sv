//SystemVerilog
module demux_valid_ready (
    input  wire        clk,             // Clock signal
    input  wire        rst,             // Synchronous reset
    input  wire        data_in,         // Input data
    input  wire [1:0]  sel_addr,        // Selection address
    input  wire        valid_in,        // Input data valid
    output wire        ready_in,        // Input data ready
    output reg  [3:0]  data_out,        // Output ports
    output reg         valid_out,       // Output data valid
    input  wire        ready_out        // Output data ready
);

    reg [3:0] data_out_next;
    reg       valid_out_next;

    assign ready_in = ready_out & (~valid_out | (valid_out & ready_out));

    always @(*) begin
        data_out_next = data_out;
        valid_out_next = valid_out;
        if (valid_in && ready_in) begin
            data_out_next = 4'b0;
            data_out_next[sel_addr] = data_in;
            valid_out_next = 1'b1;
        end else if (valid_out && ready_out) begin
            valid_out_next = 1'b0;
            data_out_next = 4'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            data_out  <= 4'b0;
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_out_next;
            valid_out <= valid_out_next;
        end
    end

endmodule