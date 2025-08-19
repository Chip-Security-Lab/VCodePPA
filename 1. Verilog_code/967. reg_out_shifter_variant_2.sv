//SystemVerilog
module reg_out_shifter (
    input clk,
    input reset_n,
    
    // AXI4-Lite Write Address Channel
    input [31:0] awaddr,
    input awvalid,
    output reg awready,
    
    // AXI4-Lite Write Data Channel
    input [31:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    output reg wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] bresp,
    output reg bvalid,
    input bready,
    
    // AXI4-Lite Read Address Channel
    input [31:0] araddr,
    input arvalid,
    output reg arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input rready,
    
    output reg serial_out
);

    reg [3:0] shift;
    reg [3:0] shift_reg;
    reg aw_en;
    reg ar_en;
    
    // Write Address Channel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~awready && awvalid && aw_en) begin
                awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (bready && bvalid) begin
                awready <= 1'b0;
                aw_en <= 1'b1;
            end else begin
                awready <= 1'b0;
            end
        end
    end
    
    // Write Data Channel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wready <= 1'b0;
        end else begin
            if (~wready && wvalid && awvalid && aw_en) begin
                wready <= 1'b1;
            end else begin
                wready <= 1'b0;
            end
        end
    end
    
    // Write Response Channel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bvalid <= 1'b0;
            bresp <= 2'b00;
        end else begin
            if (awready && awvalid && ~bvalid && wready && wvalid) begin
                bvalid <= 1'b1;
                bresp <= 2'b00;
            end else if (bready && bvalid) begin
                bvalid <= 1'b0;
            end
        end
    end
    
    // Read Address Channel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            arready <= 1'b0;
            ar_en <= 1'b1;
        end else begin
            if (~arready && arvalid && ar_en) begin
                arready <= 1'b1;
                ar_en <= 1'b0;
            end else if (rready && rvalid) begin
                arready <= 1'b0;
                ar_en <= 1'b1;
            end else begin
                arready <= 1'b0;
            end
        end
    end
    
    // Read Data Channel
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            rvalid <= 1'b0;
            rresp <= 2'b00;
            rdata <= 32'b0;
        end else begin
            if (arready && arvalid && ~rvalid) begin
                rvalid <= 1'b1;
                rresp <= 2'b00;
                rdata <= {28'b0, shift_reg};
            end else if (rready && rvalid) begin
                rvalid <= 1'b0;
            end
        end
    end
    
    // Shift register write logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 4'b0000;
        end else begin
            if (wready && wvalid && awvalid && aw_en) begin
                if (wstrb[0]) shift_reg[0] <= wdata[0];
                if (wstrb[1]) shift_reg[1] <= wdata[1];
                if (wstrb[2]) shift_reg[2] <= wdata[2];
                if (wstrb[3]) shift_reg[3] <= wdata[3];
            end
        end
    end
    
    // Shift register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift <= 4'b0000;
        end else begin
            shift <= {shift_reg[0], shift[3:1]};
        end
    end
    
    // Registered output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            serial_out <= 1'b0;
        end else begin
            serial_out <= shift[0];
        end
    end

endmodule