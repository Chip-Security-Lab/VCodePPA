//SystemVerilog
module pingpong_buf_pipeline #(parameter DW=16) (
    input                   clk,
    input                   rst_n,
    input                   switch,
    input                   valid_in,
    input      [DW-1:0]     din,
    output reg [DW-1:0]     dout,
    output reg              valid_out
);

// Combined Stage: Input Latch, Ping-Pong Buffering, and Output Selection
reg [DW-1:0] buf1_combined, buf2_combined;
reg          sel_combined;
reg [DW-1:0] dout_combined;
reg          valid_combined;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buf1_combined   <= {DW{1'b0}};
        buf2_combined   <= {DW{1'b0}};
        sel_combined    <= 1'b0;
        dout_combined   <= {DW{1'b0}};
        valid_combined  <= 1'b0;
    end else begin
        // Write path
        if (valid_in && !switch) begin
            if (sel_combined) begin
                buf2_combined <= din;
            end else begin
                buf1_combined <= din;
            end
        end

        // Switch: read out
        if (switch && valid_in) begin
            sel_combined   <= ~sel_combined;
            dout_combined  <= sel_combined ? buf1_combined : buf2_combined;
            valid_combined <= 1'b1;
        end else begin
            valid_combined <= 1'b0;
        end
    end
end

// Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout      <= {DW{1'b0}};
        valid_out <= 1'b0;
    end else begin
        dout      <= dout_combined;
        valid_out <= valid_combined;
    end
end

endmodule