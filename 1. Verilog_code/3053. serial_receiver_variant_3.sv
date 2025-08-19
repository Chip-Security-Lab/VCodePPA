//SystemVerilog
module axi4_lite_interface(
    input wire clk,
    input wire rst,
    input wire [31:0] awaddr,  // Write address
    input wire awvalid,         // Write address valid
    output reg awready,         // Write address ready
    input wire [31:0] wdata,    // Write data
    input wire wvalid,          // Write valid
    output reg wready,          // Write ready
    output reg [1:0] bresp,     // Write response
    output reg bvalid,          // Write response valid
    input wire bready,          // Write response ready
    input wire [31:0] araddr,   // Read address
    input wire arvalid,         // Read address valid
    output reg arready,         // Read address ready
    output reg [31:0] rdata,    // Read data
    output reg rvalid,          // Read valid
    input wire rready           // Read ready
);

    localparam IDLE = 3'd0, WRITE = 3'd1, READ = 3'd2;
    reg [2:0] state, next_state;
    
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        awready = 1'b0;
        wready = 1'b0;
        bvalid = 1'b0;
        arready = 1'b0;
        rvalid = 1'b0;
        
        case (state)
            IDLE: begin
                if (awvalid) begin
                    awready = 1'b1;
                    next_state = WRITE;
                end else if (arvalid) begin
                    arready = 1'b1;
                    next_state = READ;
                end
            end
            WRITE: begin
                if (wvalid) begin
                    wready = 1'b1;
                    bvalid = 1'b1;
                    bresp = 2'b00; // OKAY response
                    next_state = IDLE;
                end
            end
            READ: begin
                rdata = 32'hDEADBEEF; // Placeholder for read data
                rvalid = 1'b1;
                next_state = IDLE;
            end
        endcase
    end
endmodule