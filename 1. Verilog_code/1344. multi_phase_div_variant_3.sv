//SystemVerilog
module multi_phase_div #(parameter N=4) (
    input clk, rst,
    output [3:0] phase_out
);
    // Main counter
    reg [1:0] cnt;
    
    // Buffer registers for high fanout signal 'cnt'
    reg [1:0] cnt_buf1, cnt_buf2;
    
    // Counter logic
    always @(posedge clk) begin
        if(rst) cnt <= 0;
        else cnt <= cnt + 1;
    end
    
    // Buffer stages to reduce fanout on 'cnt'
    always @(posedge clk) begin
        if(rst) begin
            cnt_buf1 <= 0;
            cnt_buf2 <= 0;
        end
        else begin
            cnt_buf1 <= cnt;
            cnt_buf2 <= cnt;
        end
    end
    
    // Output logic using buffered counter values
    assign phase_out[3] = (cnt_buf1 == 3);  
    assign phase_out[2] = (cnt_buf1 == 2);
    assign phase_out[1] = (cnt_buf2 == 1);
    assign phase_out[0] = (cnt_buf2 == 0);
endmodule