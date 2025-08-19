//SystemVerilog
module mem_mapped_decoder(
    // AXI-Stream input interface
    input              s_axis_tvalid,
    output reg         s_axis_tready,
    input      [9:0]   s_axis_tdata,  // Combined addr[7:0] and bank_sel[1:0]
    input              s_axis_tlast,
    
    // AXI-Stream output interface
    output reg         m_axis_tvalid,
    input              m_axis_tready,
    output reg [3:0]   m_axis_tdata,  // chip_sel output
    output reg         m_axis_tlast,
    
    // Clock and reset
    input              aclk,
    input              aresetn
);
    wire [7:0] addr;
    wire [1:0] bank_sel;
    wire in_valid_range;
    reg  [3:0] chip_sel;
    reg  [9:0] operand_a, operand_b;
    wire [19:0] mult_result;
    
    // Extract original signals from AXI-Stream tdata
    assign addr = s_axis_tdata[9:2];
    assign bank_sel = s_axis_tdata[1:0];
    
    // Range check optimization
    assign in_valid_range = ~addr[7]; // addr < 8'h80
    
    // Input handshaking logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_tready <= 1'b0;
            operand_a <= 10'd0;
            operand_b <= 10'd0;
        end else begin
            s_axis_tready <= m_axis_tready || !m_axis_tvalid;
            if (s_axis_tvalid && s_axis_tready) begin
                // Store input data as operands for multiplication
                operand_a <= s_axis_tdata;
                operand_b <= {bank_sel, addr};
            end
        end
    end
    
    // Instantiate Baugh-Wooley 10-bit multiplier
    baugh_wooley_10bit multiplier (
        .a(operand_a),
        .b(operand_b),
        .product(mult_result)
    );
    
    // Core decoder logic
    always @(*) begin
        chip_sel = 4'b0000;
        if (in_valid_range)
            chip_sel[bank_sel] = 1'b1;
    end
    
    // Output data and handshaking logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'b0000;
            m_axis_tlast <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            m_axis_tvalid <= 1'b1;
            m_axis_tdata <= chip_sel;
            m_axis_tlast <= s_axis_tlast;
        end else if (m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end
endmodule

module baugh_wooley_10bit(
    input [9:0] a,
    input [9:0] b,
    output [19:0] product
);
    // Partial products
    wire [9:0] pp[9:0];
    wire [19:0] extended_pp[9:0];
    wire [19:0] sum;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 9; i = i + 1) begin: gen_pp_rows
            for (j = 0; j < 9; j = j + 1) begin: gen_pp_cols
                assign pp[i][j] = a[j] & b[i];
            end
            // Special handling for the most significant bit (Baugh-Wooley algorithm)
            assign pp[i][9] = ~(a[9] & b[i]);
        end
        
        // Last row handling
        for (j = 0; j < 9; j = j + 1) begin: gen_last_pp_cols
            assign pp[9][j] = ~(a[j] & b[9]);
        end
        // Corner case
        assign pp[9][9] = a[9] & b[9];
    endgenerate
    
    // Sign extension of partial products
    generate
        for (i = 0; i < 10; i = i + 1) begin: sign_extension
            // Shift partial product to correct position and sign-extend
            assign extended_pp[i] = {{(10-i){1'b0}}, pp[i], {i{1'b0}}};
        end
    endgenerate
    
    // Add constant for sign correction (Baugh-Wooley algorithm)
    wire [19:0] sign_correction;
    assign sign_correction = 20'b00000000010000000000; // 2^10 (for 10-bit operands)
    
    // Sum all partial products and sign correction
    assign sum = extended_pp[0] + extended_pp[1] + extended_pp[2] + extended_pp[3] + 
                 extended_pp[4] + extended_pp[5] + extended_pp[6] + extended_pp[7] + 
                 extended_pp[8] + extended_pp[9] + sign_correction;
    
    // Final product
    assign product = sum;
endmodule