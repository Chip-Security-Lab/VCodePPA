module power_on_reset_sync (
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_rst_n
);
    reg [2:0] por_counter;
    reg [1:0] ext_rst_sync;
    reg       por_done;
    
    initial begin
        por_counter = 3'b000;
        por_done = 1'b0;
    end
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_counter <= 3'b000;
            ext_rst_sync <= 2'b00;
            por_done <= 1'b0;
        end else begin
            ext_rst_sync <= {ext_rst_sync[0], 1'b1};
            
            if (!por_done)
                if (por_counter < 3'b111)
                    por_counter <= por_counter + 1;
                else
                    por_done <= 1'b1;
        end
    end
    
    assign por_rst_n = ext_rst_sync[1] & por_done;
endmodule