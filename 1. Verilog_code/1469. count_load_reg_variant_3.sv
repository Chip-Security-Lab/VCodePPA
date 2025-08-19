//SystemVerilog
module count_load_reg(
    input clk, rst,
    input [7:0] load_val,
    input load_req, count_req, 
    output reg load_ack, count_ack,
    output reg [7:0] count
);
    // Register input signals to reduce input-to-register delay
    reg [7:0] load_val_reg;
    reg load_req_reg, count_req_reg;
    
    // Register the input signals
    always @(posedge clk) begin
        if (rst) begin
            load_val_reg <= 8'h00;
            load_req_reg <= 1'b0;
            count_req_reg <= 1'b0;
            load_ack <= 1'b0;
            count_ack <= 1'b0;
        end else begin
            load_val_reg <= load_val;
            load_req_reg <= load_req;
            count_req_reg <= count_req;
            
            // Generate acknowledgment signals
            load_ack <= load_req;
            count_ack <= count_req;
        end
    end
    
    // Main counter logic using registered inputs
    always @(posedge clk) begin
        if (rst)
            count <= 8'h00;
        else if (load_req_reg && load_ack)
            count <= load_val_reg;
        else if (count_req_reg && count_ack)
            count <= count + 1'b1;
    end
endmodule