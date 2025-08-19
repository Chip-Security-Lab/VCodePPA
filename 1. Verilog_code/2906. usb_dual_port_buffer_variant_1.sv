//SystemVerilog
module usb_dual_port_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    // Port A - USB Interface
    input wire clk_a,
    input wire en_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_a_in,
    output reg [DATA_WIDTH-1:0] data_a_out,
    // Port B - System Interface
    input wire clk_b,
    input wire en_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_b_in,
    output reg [DATA_WIDTH-1:0] data_b_out
);
    // Memory array
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(1<<ADDR_WIDTH)-1:0];
    
    // Port A registers
    reg [ADDR_WIDTH-1:0] addr_a_reg;
    reg we_a_reg, en_a_reg;
    reg [DATA_WIDTH-1:0] data_a_in_reg;
    
    // Port B registers
    reg [ADDR_WIDTH-1:0] addr_b_reg;
    reg we_b_reg, en_b_reg;
    reg [DATA_WIDTH-1:0] data_b_in_reg;
    
    // Borrowing subtractor signals for address computation
    wire [ADDR_WIDTH-1:0] addr_a_next;
    wire [ADDR_WIDTH-1:0] addr_b_next;
    wire [ADDR_WIDTH:0] borrow_a;
    wire [ADDR_WIDTH:0] borrow_b;
    
    // Borrow-based subtractor for address processing
    // For Port A
    assign borrow_a[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin : gen_borrow_a
            assign addr_a_next[i] = addr_a[i] ^ 1'b0 ^ borrow_a[i];
            assign borrow_a[i+1] = (~addr_a[i] & borrow_a[i]) | (~addr_a[i] & 1'b0) | (1'b0 & borrow_a[i]);
        end
    endgenerate
    
    // For Port B
    assign borrow_b[0] = 1'b0;
    generate
        for (i = 0; i < ADDR_WIDTH; i = i + 1) begin : gen_borrow_b
            assign addr_b_next[i] = addr_b[i] ^ 1'b0 ^ borrow_b[i];
            assign borrow_b[i+1] = (~addr_b[i] & borrow_b[i]) | (~addr_b[i] & 1'b0) | (1'b0 & borrow_b[i]);
        end
    endgenerate
    
    // Port A logic
    always @(posedge clk_a) begin
        // Input registration
        addr_a_reg <= addr_a_next;
        we_a_reg <= we_a;
        en_a_reg <= en_a;
        data_a_in_reg <= data_a_in;
        
        // Memory write operation
        if (en_a && we_a)
            ram[addr_a_next] <= data_a_in;
            
        // Read operation
        if (en_a)
            data_a_out <= ram[addr_a_next];
    end
    
    // Port B logic
    always @(posedge clk_b) begin
        // Input registration
        addr_b_reg <= addr_b_next;
        we_b_reg <= we_b;
        en_b_reg <= en_b;
        data_b_in_reg <= data_b_in;
        
        // Memory write operation
        if (en_b && we_b)
            ram[addr_b_next] <= data_b_in;
            
        // Read operation
        if (en_b)
            data_b_out <= ram[addr_b_next];
    end

    // Subtractor for data path
    function [DATA_WIDTH-1:0] borrow_subtractor;
        input [DATA_WIDTH-1:0] a, b;
        reg [DATA_WIDTH:0] borrow;
        reg [DATA_WIDTH-1:0] result;
        integer j;
        begin
            borrow[0] = 1'b0;
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin
                result[j] = a[j] ^ b[j] ^ borrow[j];
                borrow[j+1] = (~a[j] & borrow[j]) | (~a[j] & b[j]) | (b[j] & borrow[j]);
            end
            borrow_subtractor = result;
        end
    endfunction
endmodule