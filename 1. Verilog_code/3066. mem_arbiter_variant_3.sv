//SystemVerilog
module mem_arbiter(
    input wire clk, rst,
    input wire req1, req2, req3,
    input wire [7:0] addr1, addr2, addr3,
    input wire [7:0] wdata1, wdata2, wdata3,
    input wire wen1, wen2, wen3,
    output reg [7:0] addr_out, wdata_out,
    output reg wen_out, grant1, grant2, grant3
);
    localparam IDLE=3'd0, GRANT1=3'd1, GRANT2=3'd2, GRANT3=3'd3;
    reg [2:0] state, next;
    
    // Combinational logic for next state and outputs
    always @(*) begin
        // Default values
        grant1 = 1'b0;
        grant2 = 1'b0;
        grant3 = 1'b0;
        addr_out = 8'd0;
        wdata_out = 8'd0;
        wen_out = 1'b0;
        next = IDLE;
        
        // Next state logic
        case(state)
            IDLE: begin
                if (req1) next = GRANT1;
                else if (req2) next = GRANT2;
                else if (req3) next = GRANT3;
            end
            GRANT1: begin
                grant1 = 1'b1;
                addr_out = addr1;
                wdata_out = wdata1;
                wen_out = wen1;
                if (req1) next = GRANT1;
                else if (req2) next = GRANT2;
                else if (req3) next = GRANT3;
            end
            GRANT2: begin
                grant2 = 1'b1;
                addr_out = addr2;
                wdata_out = wdata2;
                wen_out = wen2;
                if (req2) next = GRANT2;
                else if (req3) next = GRANT3;
                else if (req1) next = GRANT1;
            end
            GRANT3: begin
                grant3 = 1'b1;
                addr_out = addr3;
                wdata_out = wdata3;
                wen_out = wen3;
                if (req3) next = GRANT3;
                else if (req1) next = GRANT1;
                else if (req2) next = GRANT2;
            end
            default: next = IDLE;
        endcase
    end
    
    // Sequential logic for state register
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next;
    end
endmodule