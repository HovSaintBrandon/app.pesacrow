import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _blue = Color(0xFF3182CE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text('Help & FAQ',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3182CE), Color(0xFF1A559C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.help_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text('Frequently Asked Questions',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Everything you need to know about using PesaCrow safely.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildFaqItem(
            'What is PesaCrow?',
            'PesaCrow is a digital escrow platform that secures your payments when buying or selling with strangers. We hold the buyer\'s money until they confirm they\'ve received the item, then we release it to the seller.\n\n'
            'Trusting them so you don\'t have to.',
          ),
          _buildFaqItem(
            'How do I pay for a deal?',
            'Once a deal is created, the Buyer will receive an SMS from M-Pesa STK Push on their phone. Simply enter your M-Pesa PIN, and the funds will be securely moved to the PesaCrow escrow account.',
          ),
          _buildFaqItem(
            'When does the Seller get paid?',
            'The Seller is paid immediately after the Buyer approves the deal on the PesaCrow platform. If the Buyer is happy with the product, they tap "Approve," and the funds are sent to the Seller\'s M-Pesa wallet.',
          ),
          _buildFaqItem(
            'What happens if I don\'t receive my item?',
            'If the Seller fails to deliver, the Buyer can raise a dispute. Our team will investigate, and if the Seller cannot provide proof of delivery, the funds will be returned to the Buyer.',
          ),
          _buildFaqItem(
            'What are the fees?',
            'PesaCrow charges a small service fee to cover the security and infrastructure costs. You can use our "Fee Calculator" within the app to see the exact breakdown before starting a deal.',
          ),
          _buildFaqItem(
            'Can I cancel a deal?',
            'Yes, a deal can be cancelled by the Seller if they haven\'t started delivery, or by mutual agreement.\n\n'
            'If a deal is cancelled before delivery or disbursement, the escrowed funds are refunded to the Buyer fully (minus any applicable transaction fees).\n\n'
            'Once funds are in escrow, they can only be released through Buyer Approval, valid Proof of Delivery, or the official Dispute Resolution process.',
          ),
          _buildFaqItem(
            'Is PesaCrow safe?',
            'Yes. PesaCrow uses industry-standard encryption and adheres to Kenyan financial regulations. Funds are held securely, and disbursement is automated based on your authorization.',
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Still have questions? Contact support@pesacrow.top',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF1A1A1A)),
        ),
        iconColor: _blue,
        collapsedIconColor: Colors.grey.shade400,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              answer,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
