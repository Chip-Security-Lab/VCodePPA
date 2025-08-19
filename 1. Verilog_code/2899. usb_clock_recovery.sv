module usb_clock_recovery(
    input wire dp_in,
    input wire dm_in,
    input wire ref_clk,
    input wire rst_n,
    output reg recovered_clk,
    output reg bit_locked
);
    reg [2:0] edge_detect;
    reg [7:0] edge_counter;
    reg [7:0] period_count;
    
    always @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_detect <= 3'b000;
            edge_counter <= 8'd0;
            period_count <= 8'd0;
            recovered_clk <= 1'b0;
            bit_locked <= 1'b0;
        end else begin
            edge_detect <= {edge_detect[1:0], dp_in ^ dm_in};
            
            if (edge_detect[2:1] == 2'b01) begin  // Rising edge
                if (period_count > 8'd10) begin
                    bit_locked <= 1'b1;
                    period_count <= 8'd0;
                    recovered_clk <= 1'b1;
                end else begin
                    period_count <= period_count + 1'b1;
                end
            end else begin
                period_count <= period_count + 1'b1;
                if (period_count >= 8'd24) begin
                    recovered_clk <= 1'b0;
                    period_count <= 8'd0;
                end
            end
        end
    end
endmodule